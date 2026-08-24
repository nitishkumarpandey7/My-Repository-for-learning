import { Router } from 'express';
import { accountRouter } from '../modules/account/account.routes.js';
import { aiRouter } from '../modules/ai/ai.routes.js';
import { analyticsRouter } from '../modules/analytics/analytics.routes.js';
import { authRouter } from '../modules/auth/auth.routes.js';
import { dashboardRouter } from '../modules/dashboard/dashboard.routes.js';
import { gamificationRouter } from '../modules/gamification/gamification.routes.js';
import { notificationRouter } from '../modules/notifications/notification.routes.js';
import { resourceRouter } from '../modules/resources/resource.routes.js';

export const apiRouter = Router();

apiRouter.use('/auth', authRouter);
apiRouter.use('/dashboard', dashboardRouter);
apiRouter.use('/ai', aiRouter);
apiRouter.use('/analytics', analyticsRouter);
apiRouter.use('/gamification', gamificationRouter);
apiRouter.use('/notifications', notificationRouter);
apiRouter.use('/account', accountRouter);
apiRouter.use('/', resourceRouter);

