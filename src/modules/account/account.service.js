import { firebaseAuth, firebaseStorage } from '../../config/firebase.js';
import { query, transaction } from '../../config/db.js';
import { ApiError } from '../../utils/errors.js';
import { verifyPassword } from '../../utils/passwords.js';

const exportTables = [
  'user_profiles',
  'habits',
  'habit_logs',
  'bad_habits',
  'bad_habit_logs',
  'expenses',
  'income',
  'budgets',
  'savings_goals',
  'study_subjects',
  'study_topics',
  'study_sessions',
  'exams',
  'tasks',
  'reminders',
  'productivity_logs',
  'goals',
  'achievements',
  'rewards',
  'XP_logs',
  'avatars',
  'challenges',
  'challenge_progress',
  'moods',
  'analytics',
  'notifications',
  'exercise_routines',
  'exercises',
  'workout_logs',
  'syllabus_units',
  'syllabus_topics',
  'dashboard_preferences',
  'AI_chat_history',
  'login_history',
  'devices',
  'settings'
];

export const profile = async (userId) => {
  const rows = await query(
    `SELECT u.id, u.email, u.phone, u.display_name AS displayName, u.email_verified AS emailVerified,
      p.full_name AS fullName, p.avatar_url AS avatarUrl, p.timezone, p.date_of_birth AS dateOfBirth,
      p.country, p.onboarding_completed AS onboardingCompleted, p.analytics_opt_in AS analyticsOptIn,
      p.notification_opt_in AS notificationOptIn
     FROM users u
     LEFT JOIN user_profiles p ON p.user_id = u.id
     WHERE u.id = :userId
     LIMIT 1`,
    { userId }
  );
  return rows[0] ?? null;
};

export const updateProfile = async (userId, body) => {
  await query(
    `UPDATE user_profiles
     SET
      full_name = COALESCE(:fullName, full_name),
      avatar_url = COALESCE(:avatarUrl, avatar_url),
      timezone = COALESCE(:timezone, timezone),
      date_of_birth = COALESCE(:dateOfBirth, date_of_birth),
      country = COALESCE(:country, country),
      onboarding_completed = COALESCE(:onboardingCompleted, onboarding_completed),
      analytics_opt_in = COALESCE(:analyticsOptIn, analytics_opt_in),
      notification_opt_in = COALESCE(:notificationOptIn, notification_opt_in),
      updated_at = NOW()
     WHERE user_id = :userId`,
    {
      userId,
      fullName: body.fullName ?? null,
      avatarUrl: body.avatarUrl ?? null,
      timezone: body.timezone ?? null,
      dateOfBirth: body.dateOfBirth ?? null,
      country: body.country ?? null,
      onboardingCompleted:
        typeof body.onboardingCompleted === 'boolean' ? (body.onboardingCompleted ? 1 : 0) : null,
      analyticsOptIn: typeof body.analyticsOptIn === 'boolean' ? (body.analyticsOptIn ? 1 : 0) : null,
      notificationOptIn: typeof body.notificationOptIn === 'boolean' ? (body.notificationOptIn ? 1 : 0) : null
    }
  );
  return profile(userId);
};

export const exportData = async (userId) => {
  const data = {};
  const [users] = await Promise.all([query('SELECT id, email, phone, display_name, auth_provider, created_at FROM users WHERE id = :userId', { userId })]);
  data.users = users;
  for (const table of exportTables) {
    data[table] = await query(`SELECT * FROM ${table} WHERE user_id = :userId`, { userId });
  }
  return {
    exportedAt: new Date().toISOString(),
    userId,
    data
  };
};

export const requestDelete = async (userId, reason) => {
  await query(
    `UPDATE users
     SET status = 'pending_delete',
      deletion_requested_at = NOW(),
      deletion_grace_until = NOW() + INTERVAL 14 DAY,
      deletion_reason = :reason,
      updated_at = NOW()
     WHERE id = :userId`,
    { userId, reason: reason ?? null }
  );
  return query('SELECT deletion_requested_at AS requestedAt, deletion_grace_until AS graceUntil FROM users WHERE id = :userId', {
    userId
  });
};

export const cancelDelete = async (userId) => {
  await query(
    `UPDATE users
     SET status = 'active', deletion_requested_at = NULL, deletion_grace_until = NULL, deletion_reason = NULL, updated_at = NOW()
     WHERE id = :userId AND status = 'pending_delete'`,
    { userId }
  );
  return profile(userId);
};

const deleteFirebaseArtifacts = async (user) => {
  if (firebaseAuth && user.firebase_uid) {
    await firebaseAuth.deleteUser(user.firebase_uid).catch(() => null);
  }

  if (firebaseStorage) {
    const bucket = firebaseStorage.bucket();
    await bucket.deleteFiles({ prefix: `users/${user.id}/`, force: true }).catch(() => null);
  }
};

export const confirmDelete = async ({ userId, password }) =>
  transaction(async (connection) => {
    const [users] = await connection.execute('SELECT * FROM users WHERE id = :userId LIMIT 1', { userId });
    const user = users[0];
    if (!user) throw new ApiError(404, 'User not found');

    if (user.password_hash) {
      if (!password) throw new ApiError(401, 'Password is required for local account deletion');
      const ok = await verifyPassword(password, user.password_hash);
      if (!ok) throw new ApiError(401, 'Invalid password');
    }

    await deleteFirebaseArtifacts(user);
    await connection.execute('DELETE FROM users WHERE id = :userId', { userId });
    return { deleted: true, userId };
  });

export const logoutAllDevices = async (userId) => {
  await query('UPDATE devices SET revoked_at = NOW(), updated_at = NOW() WHERE user_id = :userId', { userId });
  return { revoked: true };
};

