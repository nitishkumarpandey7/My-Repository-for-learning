import { createApp } from './app.js';
import { env } from './config/env.js';
import { logger } from './config/logger.js';
import { closePool } from './config/db.js';

const app = createApp();
const server = app.listen(env.port, () => {
  logger.info(`LifeOS X API listening on http://localhost:${env.port}`);
});

const shutdown = async (signal) => {
  logger.info({ signal }, 'Shutting down LifeOS X API');
  server.close(async () => {
    await closePool();
    process.exit(0);
  });
};

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

