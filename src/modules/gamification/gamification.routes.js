import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import * as controller from './gamification.controller.js';

export const gamificationRouter = Router();

gamificationRouter.get('/leaderboard', controller.leaderboard);
gamificationRouter.post('/daily-reward', requireAuth, controller.claimDailyReward);
gamificationRouter.post('/ai-challenge', requireAuth, controller.aiChallenge);

