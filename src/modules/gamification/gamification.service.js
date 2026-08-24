import { query } from '../../config/db.js';
import { id } from '../../utils/ids.js';
import { runAi } from '../ai/ai.service.js';

export const awardXp = async ({ userId, points, reason, domain = 'general', referenceId = null }) => {
  await query(
    `INSERT INTO XP_logs
      (id, user_id, points, reason, domain, reference_id, created_at, updated_at)
     VALUES (:id, :userId, :points, :reason, :domain, :referenceId, NOW(), NOW())`,
    { id: id(), userId, points, reason, domain, referenceId }
  );
  const rows = await query('SELECT COALESCE(SUM(points), 0) AS xp FROM XP_logs WHERE user_id = :userId', { userId });
  return {
    points,
    totalXp: Number(rows[0]?.xp ?? 0),
    level: Math.floor(Number(rows[0]?.xp ?? 0) / 1000) + 1
  };
};

export const claimDailyReward = async (userId) => {
  const rows = await query(
    `SELECT id FROM XP_logs
     WHERE user_id = :userId AND reason = 'daily_reward' AND DATE(created_at) = CURRENT_DATE()
     LIMIT 1`,
    { userId }
  );
  if (rows.length) return { alreadyClaimed: true, ...(await awardXp({ userId, points: 0, reason: 'daily_reward_check' })) };
  return awardXp({ userId, points: 50, reason: 'daily_reward', domain: 'gamification' });
};

export const leaderboard = () =>
  query(
    `SELECT u.id, COALESCE(p.full_name, u.display_name, 'LifeOS User') AS name,
      COALESCE(SUM(x.points), 0) AS xp,
      FLOOR(COALESCE(SUM(x.points), 0) / 1000) + 1 AS level
     FROM users u
     LEFT JOIN user_profiles p ON p.user_id = u.id
     LEFT JOIN XP_logs x ON x.user_id = u.id
     WHERE u.status = 'active'
     GROUP BY u.id, name
     ORDER BY xp DESC
     LIMIT 50`
  );

export const aiChallenge = async (userId, domain) => {
  const result = await runAi({
    domain,
    messages: [
      {
        role: 'user',
        content: `Create one ${domain} challenge for today. Return a short title, a motivating description, and a measurable completion rule.`
      }
    ]
  });
  const challengeId = id();
  await query(
    `INSERT INTO challenges
      (id, user_id, title, description, domain, difficulty, starts_at, ends_at, xp_reward, coin_reward, status, created_at, updated_at)
     VALUES (:id, :userId, :title, :description, :domain, 'medium', NOW(), NOW() + INTERVAL 1 DAY, 100, 25, 'active', NOW(), NOW())`,
    {
      id: challengeId,
      userId,
      title: `AI ${domain} mission`,
      description: result.content,
      domain
    }
  );
  return { id: challengeId, domain, provider: result.provider, content: result.content };
};

