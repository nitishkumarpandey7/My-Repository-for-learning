import { asyncHandler } from '../../utils/errors.js';
import * as service from './analytics.service.js';

export const report = asyncHandler(async (req, res) => {
  const data = await service.report(req.user.id, req.params.domain, req.query.days);
  res.json({ ok: true, data });
});

export const burnout = asyncHandler(async (req, res) => {
  const data = await service.burnout(req.user.id);
  res.json({ ok: true, data });
});

