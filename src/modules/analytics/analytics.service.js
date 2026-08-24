import { query } from '../../config/db.js';

const domainQueries = {
  habits: `SELECT log_date AS date, SUM(status = 'completed') AS completed, COUNT(*) AS total
           FROM habit_logs WHERE user_id = :userId AND log_date >= CURRENT_DATE() - INTERVAL :days DAY
           GROUP BY log_date ORDER BY log_date`,
  finance: `SELECT DATE(spent_at) AS date, category, SUM(amount) AS amount
            FROM expenses WHERE user_id = :userId AND spent_at >= CURRENT_DATE() - INTERVAL :days DAY
            GROUP BY DATE(spent_at), category ORDER BY date`,
  study: `SELECT DATE(started_at) AS date, SUM(duration_minutes) AS minutes, AVG(focus_score) AS focusScore
          FROM study_sessions WHERE user_id = :userId AND started_at >= CURRENT_DATE() - INTERVAL :days DAY
          GROUP BY DATE(started_at) ORDER BY date`,
  productivity: `SELECT log_date AS date, deep_work_minutes AS deepWorkMinutes, distraction_minutes AS distractionMinutes, focus_score AS focusScore
                 FROM productivity_logs WHERE user_id = :userId AND log_date >= CURRENT_DATE() - INTERVAL :days DAY
                 ORDER BY log_date`,
  recovery: `SELECT log_date AS date, SUM(relapsed = 1) AS relapses, AVG(urge_level) AS averageUrge
             FROM bad_habit_logs WHERE user_id = :userId AND log_date >= CURRENT_DATE() - INTERVAL :days DAY
             GROUP BY log_date ORDER BY log_date`
};

export const report = async (userId, domain, days = 30) => {
  const sql = domainQueries[domain] ?? domainQueries.productivity;
  const safeDays = Math.min(Math.max(Number(days) || 30, 7), 365);
  const rows = await query(sql, { userId, days: safeDays });
  return {
    domain,
    days: safeDays,
    data: rows,
    generatedAt: new Date().toISOString()
  };
};

export const burnout = async (userId) => {
  const rows = await query(
    `SELECT
      COALESCE(AVG(m.stress), 0) AS stress,
      COALESCE(AVG(m.energy), 0) AS energy,
      COALESCE(AVG(m.sleep_quality), 0) AS sleepQuality,
      COALESCE(SUM(p.distraction_minutes), 0) AS distractionMinutes,
      COALESCE(SUM(p.deep_work_minutes), 0) AS deepWorkMinutes
     FROM moods m
     LEFT JOIN productivity_logs p ON p.user_id = m.user_id AND p.log_date = m.mood_date
     WHERE m.user_id = :userId AND m.mood_date >= CURRENT_DATE() - INTERVAL 14 DAY`,
    { userId }
  );
  const stat = rows[0] ?? {};
  const score = Math.max(
    0,
    Math.min(
      100,
      Math.round(Number(stat.stress) * 12 + (10 - Number(stat.energy)) * 7 + (10 - Number(stat.sleepQuality)) * 5)
    )
  );
  return {
    score,
    status: score > 70 ? 'high_risk' : score > 40 ? 'watch' : 'stable',
    signals: stat
  };
};

