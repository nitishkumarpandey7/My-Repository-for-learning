import { firebaseMessaging } from '../../config/firebase.js';
import { query } from '../../config/db.js';
import { id } from '../../utils/ids.js';

export const createNotification = async ({ userId, title, body, type = 'general', payload = {}, scheduledAt = null }) => {
  const notificationId = id();
  await query(
    `INSERT INTO notifications
      (id, user_id, title, body, type, payload, scheduled_at, status, created_at, updated_at)
     VALUES (:id, :userId, :title, :body, :type, :payload, :scheduledAt, 'queued', NOW(), NOW())`,
    {
      id: notificationId,
      userId,
      title,
      body,
      type,
      payload: JSON.stringify(payload),
      scheduledAt
    }
  );
  return { id: notificationId, title, body, type, payload, scheduledAt };
};

export const sendNow = async ({ userId, title, body, type, payload }) => {
  const notification = await createNotification({ userId, title, body, type, payload });
  const devices = await query(
    'SELECT fcm_token AS fcmToken FROM devices WHERE user_id = :userId AND fcm_token IS NOT NULL AND revoked_at IS NULL',
    { userId }
  );
  const tokens = devices.map((device) => device.fcmToken).filter(Boolean);

  if (firebaseMessaging && tokens.length) {
    await firebaseMessaging.sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(payload ?? {}).map(([key, value]) => [key, String(value)]))
    });
    await query('UPDATE notifications SET sent_at = NOW(), status = "sent", updated_at = NOW() WHERE id = :id', {
      id: notification.id
    });
  }

  return { ...notification, deliveredToDevices: tokens.length, fcmConfigured: Boolean(firebaseMessaging) };
};

