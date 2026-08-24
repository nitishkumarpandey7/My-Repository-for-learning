import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import * as controller from './notification.controller.js';

export const notificationRouter = Router();

notificationRouter.use(requireAuth);
notificationRouter.post('/', controller.validateNotification, controller.create);
notificationRouter.post('/send', controller.validateNotification, controller.send);

