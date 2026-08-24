import { query } from '../../config/db.js';

const clamp = (value, min = 0, max = 100) => Math.max(min, Math.min(max, Math.round(value)));

export const getDashboard = async (userId) => {
  const [profile, habits, tasks, finance, study, xp, challenges, mood, insights] = await Promise.all([
    query(
      `SELECT u.id, u.email, u.display_name AS displayName, p.full_name AS fullName,
        p.avatar_url AS avatarUrl, p.timezone
       FROM users u
       LEFT JOIN user_profiles p ON p.user_id = u.id
       WHERE u.id = :userId
       LIMIT 1`,
      { userId }
    ),
    query(
      `SELECT
        COUNT(DISTINCT h.id) AS totalHabits,
        SUM(CASE WHEN h.is_active = 1 THEN 1 ELSE 0 END) AS activeHabits,
        SUM(CASE WHEN hl.status = 'completed' AND hl.log_date >= CURRENT_DATE() - INTERVAL 7 DAY THEN 1 ELSE 0 END) AS weeklyCompletions
       FROM habits h
       LEFT JOIN habit_logs hl ON hl.habit_id = h.id AND hl.user_id = h.user_id
       WHERE h.user_id = :userId`,
      { userId }
    ),
    query(
      `SELECT
        SUM(CASE WHEN status = 'done' THEN 1 ELSE 0 END) AS done,
        SUM(CASE WHEN status <> 'done' AND (due_at IS NULL OR due_at >= NOW()) THEN 1 ELSE 0 END) AS open,
        SUM(CASE WHEN status <> 'done' AND due_at < NOW() THEN 1 ELSE 0 END) AS overdue
       FROM tasks
       WHERE user_id = :userId`,
      { userId }
    ),
    query(
      `SELECT
        COALESCE((SELECT SUM(amount) FROM expenses WHERE user_id = :userId AND spent_at >= DATE_FORMAT(CURRENT_DATE(), '%Y-%m-01')), 0) AS monthExpenses,
        COALESCE((SELECT SUM(amount) FROM income WHERE user_id = :userId AND received_at >= DATE_FORMAT(CURRENT_DATE(), '%Y-%m-01')), 0) AS monthIncome,
        COALESCE((SELECT SUM(current_amount) FROM savings_goals WHERE user_id = :userId), 0) AS savings
      `,
      { userId }
    ),
    query(
      `SELECT
        COALESCE(SUM(duration_minutes), 0) AS weekStudyMinutes,
        COALESCE(AVG(focus_score), 0) AS focusScore
       FROM study_sessions
       WHERE user_id = :userId AND started_at >= NOW() - INTERVAL 7 DAY`,
      { userId }
    ),
    query(
      `SELECT
        COALESCE(SUM(points), 0) AS xp,
        COUNT(*) AS xpEvents
       FROM XP_logs
       WHERE user_id = :userId`,
      { userId }
    ),
    query(
      `SELECT COUNT(*) AS activeChallenges
       FROM challenges
       WHERE user_id = :userId AND status = 'active' AND (ends_at IS NULL OR ends_at >= NOW())`,
      { userId }
    ),
    query(
      `SELECT score, energy, stress, sleep_quality AS sleepQuality, mood_date AS moodDate
       FROM moods
       WHERE user_id = :userId
       ORDER BY mood_date DESC
       LIMIT 1`,
      { userId }
    ),
    query(
      `SELECT content, provider, created_at AS createdAt
       FROM AI_chat_history
       WHERE user_id = :userId AND role = 'assistant'
       ORDER BY created_at DESC
       LIMIT 3`,
      { userId }
    )
  ]);

  const habit = habits[0] ?? {};
  const task = tasks[0] ?? {};
  const money = finance[0] ?? {};
  const studyStats = study[0] ?? {};
  const xpStats = xp[0] ?? {};
  const activeChallenges = challenges[0]?.activeChallenges ?? 0;
  const income = Number(money.monthIncome ?? 0);
  const expenses = Number(money.monthExpenses ?? 0);
  const savingsRate = income > 0 ? ((income - expenses) / income) * 100 : 0;
  const taskScore = clamp((Number(task.done ?? 0) / Math.max(Number(task.done ?? 0) + Number(task.open ?? 0) + Number(task.overdue ?? 0), 1)) * 100);
  const habitScore = clamp((Number(habit.weeklyCompletions ?? 0) / Math.max(Number(habit.activeHabits ?? 1) * 7, 1)) * 100);
  const studyScore = clamp((Number(studyStats.weekStudyMinutes ?? 0) / 600) * 100);
  const financeScore = clamp(55 + savingsRate - Number(task.overdue ?? 0) * 2);
  const lifeScore = clamp((habitScore * 0.3 + taskScore * 0.25 + studyScore * 0.2 + financeScore * 0.15 + Math.min(Number(xpStats.xp ?? 0) / 20, 100) * 0.1));

  return {
    profile: profile[0] ?? null,
    scores: {
      lifeScore,
      habitScore,
      taskScore,
      studyScore,
      financeScore,
      productivityScore: clamp((taskScore + studyScore + habitScore) / 3)
    },
    habits: habit,
    tasks: task,
    finance: money,
    study: studyStats,
    gamification: {
      xp: Number(xpStats.xp ?? 0),
      level: Math.floor(Number(xpStats.xp ?? 0) / 1000) + 1,
      activeChallenges
    },
    mood: mood[0] ?? null,
    insights
  };
};

export const updateWidget = async (userId, widget) => {
  await query(
    `INSERT INTO dashboard_preferences
      (id, user_id, widget_key, layout, is_visible, sort_order, settings, created_at, updated_at)
     VALUES (UUID(), :userId, :widgetKey, :layout, :isVisible, :sortOrder, :settings, NOW(), NOW())
     ON DUPLICATE KEY UPDATE
      layout = VALUES(layout),
      is_visible = VALUES(is_visible),
      sort_order = VALUES(sort_order),
      settings = VALUES(settings),
      updated_at = NOW()`,
    {
      userId,
      widgetKey: widget.widgetKey,
      layout: JSON.stringify(widget.layout ?? {}),
      isVisible: widget.isVisible === false ? 0 : 1,
      sortOrder: widget.sortOrder ?? 0,
      settings: JSON.stringify(widget.settings ?? {})
    }
  );
  return query('SELECT * FROM dashboard_preferences WHERE user_id = :userId ORDER BY sort_order ASC', { userId });
};

