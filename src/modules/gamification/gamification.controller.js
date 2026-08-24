import { asyncHandler } from '../../utils/errors.js';
import * as service from './gamification.service.js';

export const claimDailyReward = asyncHandler(async (req, res) => {
  const data = await service.claimDailyReward(req.user.id);
  res.json({ ok: true, data });
});

export const leaderboard = asyncHandler(async (_req, res) => {
  const data = await service.leaderboard();
  res.json({ ok: true, data });
});

export const aiChallenge = asyncHandler(async (req, res) => {
  const data = await service.aiChallenge(req.user.id, req.body.domain ?? 'discipline');
  res.status(201).json({ ok: true, data });
});

