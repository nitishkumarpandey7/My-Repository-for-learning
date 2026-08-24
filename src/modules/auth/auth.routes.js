import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import * as controller from './auth.controller.js';
import {
  biometricSchema,
  firebaseLoginSchema,
  forgotPasswordSchema,
  loginSchema,
  refreshSchema,
  registerSchema
} from './auth.schemas.js';

export const authRouter = Router();

authRouter.post('/register', validate(registerSchema), controller.register);
authRouter.post('/login', validate(loginSchema), controller.login);
authRouter.post('/refresh', validate(refreshSchema), controller.refresh);
authRouter.post('/firebase', validate(firebaseLoginSchema), controller.firebaseLogin);
authRouter.post('/guest', controller.guestLogin);
authRouter.post('/forgot-password', validate(forgotPasswordSchema), controller.forgotPassword);
authRouter.post('/logout', requireAuth, controller.logout);
authRouter.patch('/biometric', requireAuth, validate(biometricSchema), controller.enableBiometric);
authRouter.get('/login-history', requireAuth, controller.loginHistory);

