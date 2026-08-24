import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.js';
import { resourceConfig } from './resource.config.js';
import * as controller from './resource.controller.js';

export const resourceRouter = Router();

for (const slug of Object.keys(resourceConfig)) {
  resourceRouter
    .route(`/${slug}`)
    .all(requireAuth, controller.attachResource(slug))
    .get(controller.list)
    .post(controller.create);

  resourceRouter
    .route(`/${slug}/:id`)
    .all(requireAuth, controller.attachResource(slug))
    .get(controller.get)
    .patch(controller.update)
    .delete(controller.remove);
}

