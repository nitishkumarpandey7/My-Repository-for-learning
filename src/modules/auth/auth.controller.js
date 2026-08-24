import * as auth from './auth.service.js';
import { asyncHandler } from '../../utils/errors.js';

export const register = asyncHandler(async (req, res) => {
  const result = await auth.register(req.validated.body, req);
  res.status(201).json({ ok: true, data: result });
});

export const login = asyncHandler(async (req, res) => {
  const result = await auth.login(req.validated.body, req);
  res.json({ ok: true, data: result });
});

export const refresh = asyncHandler(async (req, res) => {
  const result = await auth.refresh(req.validated.body.refreshToken);
  res.json({ ok: true, data: result });
});

export const firebaseLogin = asyncHandler(async (req, res) => {
  const result = await auth.firebaseLogin(req.validated.body, req);
  res.json({ ok: true, data: result });
});

export const guestLogin = asyncHandler(async (req, res) => {
  const result = await auth.guestLogin(req);
  res.status(201).json({ ok: true, data: result });
});

export const forgotPassword = asyncHandler(async (req, res) => {
  const result = await auth.forgotPassword(req.validated.body);
  res.json({ ok: true, data: result });
});

export const enableBiometric = asyncHandler(async (req, res) => {
  const result = await auth.setBiometricPreference({
    userId: req.user.id,
    ...req.validated.body
  });
  res.json({ ok: true, data: result });
});

export const loginHistory = asyncHandler(async (req, res) => {
  const result = await auth.getLoginHistory(req.user.id);
  res.json({ ok: true, data: result });
});

export const logout = asyncHandler(async (_req, res) => {
  res.json({ ok: true, data: { message: 'Client token discarded. Use logout-all to revoke trusted devices.' } });
});

