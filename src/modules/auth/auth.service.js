import { firebaseAuth } from '../../config/firebase.js';
import { query, transaction } from '../../config/db.js';
import { ApiError } from '../../utils/errors.js';
import { id } from '../../utils/ids.js';
import { hashPassword, verifyPassword } from '../../utils/passwords.js';
import { signAccessToken, signRefreshToken, verifyRefreshToken } from '../../utils/tokens.js';

const publicUser = (user) => ({
  id: user.id,
  email: user.email,
  phone: user.phone ?? null,
  displayName: user.display_name ?? user.displayName ?? null,
  role: user.role ?? 'user',
  emailVerified: Boolean(user.email_verified ?? user.emailVerified),
  authProvider: user.auth_provider ?? user.authProvider,
  status: user.status
});

const tokenBundle = (user) => ({
  user: publicUser(user),
  accessToken: signAccessToken(user),
  refreshToken: signRefreshToken(user)
});

const recordLogin = async (connection, { userId, req, device, suspicious = false }) => {
  await connection.execute(
    `INSERT INTO login_history
      (id, user_id, ip_address, user_agent, device_label, success, suspicious, created_at)
     VALUES (:id, :userId, :ip, :agent, :deviceLabel, 1, :suspicious, NOW())`,
    {
      id: id(),
      userId,
      ip: req.ip,
      agent: req.headers['user-agent'] ?? null,
      deviceLabel: [device?.platform, device?.model].filter(Boolean).join(' ') || null,
      suspicious: suspicious ? 1 : 0
    }
  );

  if (device?.deviceId) {
    await connection.execute(
      `INSERT INTO devices
        (id, user_id, device_id, platform, model, app_version, fcm_token, last_seen_at, trusted, created_at, updated_at)
       VALUES (:id, :userId, :deviceId, :platform, :model, :appVersion, :fcmToken, NOW(), 1, NOW(), NOW())
       ON DUPLICATE KEY UPDATE
        platform = VALUES(platform),
        model = VALUES(model),
        app_version = VALUES(app_version),
        fcm_token = VALUES(fcm_token),
        last_seen_at = NOW(),
        updated_at = NOW()`,
      {
        id: id(),
        userId,
        deviceId: device.deviceId,
        platform: device.platform ?? null,
        model: device.model ?? null,
        appVersion: device.appVersion ?? null,
        fcmToken: device.fcmToken ?? null
      }
    );
  }
};

export const register = async ({ email, password, displayName, timezone }, req) =>
  transaction(async (connection) => {
    const [existing] = await connection.execute('SELECT id FROM users WHERE email = :email LIMIT 1', { email });
    if (existing.length) throw new ApiError(409, 'Email is already registered');

    const userId = id();
    const passwordHash = await hashPassword(password);
    await connection.execute(
      `INSERT INTO users
        (id, email, password_hash, display_name, role, auth_provider, email_verified, status, created_at, updated_at)
       VALUES (:id, :email, :passwordHash, :displayName, 'user', 'local', 0, 'active', NOW(), NOW())`,
      { id: userId, email, passwordHash, displayName: displayName ?? null }
    );

    await connection.execute(
      `INSERT INTO user_profiles
        (id, user_id, full_name, timezone, onboarding_completed, analytics_opt_in, created_at, updated_at)
       VALUES (:id, :userId, :fullName, :timezone, 0, 1, NOW(), NOW())`,
      { id: id(), userId, fullName: displayName ?? null, timezone }
    );

    await recordLogin(connection, { userId, req, device: undefined });

    return tokenBundle({
      id: userId,
      email,
      display_name: displayName,
      role: 'user',
      auth_provider: 'local',
      email_verified: 0,
      status: 'active'
    });
  });

export const login = async ({ email, password, device }, req) =>
  transaction(async (connection) => {
    const [users] = await connection.execute(
      'SELECT * FROM users WHERE email = :email AND status = "active" LIMIT 1',
      { email }
    );
    const user = users[0];
    if (!user?.password_hash) throw new ApiError(401, 'Invalid email or password');

    const ok = await verifyPassword(password, user.password_hash);
    if (!ok) {
      await connection.execute(
        `INSERT INTO login_history
          (id, user_id, ip_address, user_agent, success, suspicious, created_at)
         VALUES (:id, :userId, :ip, :agent, 0, 1, NOW())`,
        {
          id: id(),
          userId: user.id,
          ip: req.ip,
          agent: req.headers['user-agent'] ?? null
        }
      );
      throw new ApiError(401, 'Invalid email or password');
    }

    const [knownDevices] = device?.deviceId
      ? await connection.execute('SELECT id FROM devices WHERE user_id = :userId AND device_id = :deviceId LIMIT 1', {
          userId: user.id,
          deviceId: device.deviceId
        })
      : [[]];
    const suspicious = Boolean(device?.deviceId && knownDevices.length === 0);

    await recordLogin(connection, { userId: user.id, req, device, suspicious });
    return tokenBundle(user);
  });

export const refresh = async (refreshToken) => {
  const decoded = verifyRefreshToken(refreshToken);
  if (decoded.type !== 'refresh') throw new ApiError(401, 'Invalid refresh token');
  const users = await query('SELECT * FROM users WHERE id = :id AND status = "active" LIMIT 1', { id: decoded.sub });
  if (!users.length) throw new ApiError(401, 'User no longer exists');
  return tokenBundle(users[0]);
};

export const firebaseLogin = async ({ idToken, provider, device }, req) => {
  if (!firebaseAuth) throw new ApiError(503, 'Firebase Admin is not configured on this server');
  const decoded = await firebaseAuth.verifyIdToken(idToken);

  return transaction(async (connection) => {
    const [existing] = await connection.execute(
      'SELECT * FROM users WHERE firebase_uid = :firebaseUid OR email = :email LIMIT 1',
      {
        firebaseUid: decoded.uid,
        email: decoded.email ?? null
      }
    );

    let user = existing[0];
    if (!user) {
      const userId = id();
      await connection.execute(
        `INSERT INTO users
          (id, firebase_uid, email, phone, display_name, role, auth_provider, email_verified, status, created_at, updated_at)
         VALUES (:id, :firebaseUid, :email, :phone, :displayName, 'user', :provider, :emailVerified, 'active', NOW(), NOW())`,
        {
          id: userId,
          firebaseUid: decoded.uid,
          email: decoded.email ?? null,
          phone: decoded.phone_number ?? null,
          displayName: decoded.name ?? null,
          provider,
          emailVerified: decoded.email_verified ? 1 : 0
        }
      );
      await connection.execute(
        `INSERT INTO user_profiles
          (id, user_id, full_name, timezone, onboarding_completed, analytics_opt_in, created_at, updated_at)
         VALUES (:id, :userId, :fullName, 'Asia/Calcutta', 0, 1, NOW(), NOW())`,
        { id: id(), userId, fullName: decoded.name ?? null }
      );
      user = {
        id: userId,
        email: decoded.email,
        phone: decoded.phone_number,
        display_name: decoded.name,
        role: 'user',
        auth_provider: provider,
        email_verified: decoded.email_verified ? 1 : 0,
        status: 'active'
      };
    } else if (!user.firebase_uid) {
      await connection.execute(
        `UPDATE users
         SET firebase_uid = :firebaseUid, auth_provider = :provider, email_verified = :emailVerified, updated_at = NOW()
         WHERE id = :id`,
        {
          id: user.id,
          firebaseUid: decoded.uid,
          provider,
          emailVerified: decoded.email_verified ? 1 : 0
        }
      );
      user.firebase_uid = decoded.uid;
      user.auth_provider = provider;
    }

    await recordLogin(connection, { userId: user.id, req, device });
    return tokenBundle(user);
  });
};

export const guestLogin = async (req) =>
  transaction(async (connection) => {
    const userId = id();
    const guestEmail = `guest-${userId}@lifeos.local`;
    await connection.execute(
      `INSERT INTO users
        (id, email, display_name, role, auth_provider, email_verified, status, created_at, updated_at)
       VALUES (:id, :email, 'Guest Explorer', 'guest', 'guest', 0, 'active', NOW(), NOW())`,
      { id: userId, email: guestEmail }
    );
    await connection.execute(
      `INSERT INTO user_profiles
        (id, user_id, full_name, timezone, onboarding_completed, analytics_opt_in, created_at, updated_at)
       VALUES (:id, :userId, 'Guest Explorer', 'Asia/Calcutta', 0, 0, NOW(), NOW())`,
      { id: id(), userId }
    );
    await recordLogin(connection, { userId, req });
    return tokenBundle({
      id: userId,
      email: guestEmail,
      display_name: 'Guest Explorer',
      role: 'guest',
      auth_provider: 'guest',
      email_verified: 0,
      status: 'active'
    });
  });

export const setBiometricPreference = async ({ userId, enabled, deviceId }) => {
  await query(
    `UPDATE devices
     SET biometric_enabled = :enabled, updated_at = NOW()
     WHERE user_id = :userId AND device_id = :deviceId`,
    { userId, enabled: enabled ? 1 : 0, deviceId }
  );
  return { enabled, deviceId };
};

export const getLoginHistory = (userId) =>
  query(
    `SELECT id, ip_address AS ipAddress, user_agent AS userAgent, device_label AS deviceLabel,
      success, suspicious, created_at AS createdAt
     FROM login_history
     WHERE user_id = :userId
     ORDER BY created_at DESC
     LIMIT 50`,
    { userId }
  );

export const forgotPassword = async ({ email }) => {
  if (firebaseAuth) {
    const link = await firebaseAuth.generatePasswordResetLink(email);
    return { delivery: 'firebase', resetLink: link };
  }
  return {
    delivery: 'manual',
    message: 'Configure Firebase Admin to send password reset links.'
  };
};

