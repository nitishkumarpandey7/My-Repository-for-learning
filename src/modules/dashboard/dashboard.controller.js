import { z } from 'zod';
import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/errors.js';
import * as service from './dashboard.service.js';

export const widgetSchema = z.object({
  body: z.object({
    widgetKey: z.string().min(1).max(80),
    layout: z.record(z.string(), z.any()).optional(),
    isVisible: z.boolean().optional(),
    sortOrder: z.number().int().optional(),
    settings: z.record(z.string(), z.any()).optional()
  })
});

export const validateWidget = validate(widgetSchema);

export const dashboard = asyncHandler(async (req, res) => {
  const data = await service.getDashboard(req.user.id);
  res.json({ ok: true, data });
});

export const updateWidget = asyncHandler(async (req, res) => {
  const data = await service.updateWidget(req.user.id, req.validated.body);
  res.json({ ok: true, data });
});
