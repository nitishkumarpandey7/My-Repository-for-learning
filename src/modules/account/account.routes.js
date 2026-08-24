import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import * as controller from './account.controller.js';

export const accountRouter = Router();

accountRouter.use(requireAuth);
accountRouter.get('/profile', controller.profile);
accountRouter.patch('/profile', controller.validateProfile, controller.updateProfile);
accountRouter.get('/export', controller.exportData);
accountRouter.post('/delete/request', controller.validateDeleteRequest, controller.requestDelete);
accountRouter.post('/delete/cancel', controller.cancelDelete);
accountRouter.post('/delete/confirm', controller.validateConfirmDelete, controller.confirmDelete);
accountRouter.post('/logout-all-devices', controller.logoutAllDevices);

