import { validate } from '../../middleware/validate.js';
import { asyncHandler } from '../../utils/errors.js';
import * as service from './account.service.js';
import { confirmDeleteSchema, deleteRequestSchema, profileSchema } from './account.schemas.js';

export const validateProfile = validate(profileSchema);
export const validateDeleteRequest = validate(deleteRequestSchema);
export const validateConfirmDelete = validate(confirmDeleteSchema);

export const profile = asyncHandler(async (req, res) => {
  const data = await service.profile(req.user.id);
  res.json({ ok: true, data });
});

export const updateProfile = asyncHandler(async (req, res) => {
  const data = await service.updateProfile(req.user.id, req.validated.body);
  res.json({ ok: true, data });
});

export const exportData = asyncHandler(async (req, res) => {
  const data = await service.exportData(req.user.id);
  res.json({ ok: true, data });
});

export const requestDelete = asyncHandler(async (req, res) => {
  const data = await service.requestDelete(req.user.id, req.validated.body.reason);
  res.json({ ok: true, data });
});

export const cancelDelete = asyncHandler(async (req, res) => {
  const data = await service.cancelDelete(req.user.id);
  res.json({ ok: true, data });
});

export const confirmDelete = asyncHandler(async (req, res) => {
  const data = await service.confirmDelete({ userId: req.user.id, password: req.validated.body.password });
  res.json({ ok: true, data });
});

export const logoutAllDevices = asyncHandler(async (req, res) => {
  const data = await service.logoutAllDevices(req.user.id);
  res.json({ ok: true, data });
});

