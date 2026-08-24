import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import * as controller from './ai.controller.js';
import { chatSchema, recommendationSchema } from './ai.schemas.js';

export const aiRouter = Router();

aiRouter.use(requireAuth);
aiRouter.get('/conversations', controller.conversations);
aiRouter.post('/chat', validate(chatSchema), controller.chat);
aiRouter.post('/chat/stream', validate(chatSchema), controller.streamChat);
aiRouter.post('/recommendations', validate(recommendationSchema), controller.recommendation);

