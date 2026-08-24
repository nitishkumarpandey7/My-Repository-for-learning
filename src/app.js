import express from 'express';
import swaggerUi from 'swagger-ui-express';
import YAML from 'yamljs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { env } from './config/env.js';
import { pingDatabase } from './config/db.js';
import { applySecurity } from './middleware/security.js';
import { errorHandler, notFound } from './middleware/errorHandler.js';
import { apiRouter } from './routes/index.js';
import { asyncHandler } from './utils/errors.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const swaggerDocument = YAML.load(join(__dirname, '..', 'swagger', 'openapi.yaml'));

export const createApp = () => {
  const app = express();
  applySecurity(app);

  app.get('/health', (_req, res) => {
    res.json({
      ok: true,
      service: 'LifeOS X API',
      version: process.env.npm_package_version ?? '1.0.0',
      timestamp: new Date().toISOString()
    });
  });

  app.get(
    '/ready',
    asyncHandler(async (_req, res) => {
      const db = await pingDatabase();
      res.status(db ? 200 : 503).json({ ok: db, db });
    })
  );

  app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
  app.use(`/api/${env.apiVersion}`, apiRouter);
  app.use(notFound);
  app.use(errorHandler);

  return app;
};

