import { z } from 'zod';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/errors.js';
import * as service from './notification.service.js';

export const notificationSchema = z.object({
  body: z.object({
    title: z.string().min(1).max(140),
    body: z.string().min(1).max(500),
    type: z.string().max(60).optional(),
    payload: z.record(z.string(), z.any()).optional(),
    scheduledAt: z.string().datetime().optional()
  })
});

export const validateNotification = validate(notificationSchema);

export const create = asyncHandler(async (req, res) => {
  const data = await service.createNotification({ userId: req.user.id, ...req.validated.body });
  res.status(201).json({ ok: true, data });
});

export const send = asyncHandler(async (req, res) => {
  const data = await service.sendNow({ userId: req.user.id, ...req.validated.body });
  res.json({ ok: true, data });
});
