import compression from 'compression';
import cors from 'cors';
import express from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import pinoHttp from 'pino-http';
import { env } from '../config/env.js';
import { logger } from '../config/logger.js';

export const applySecurity = (app) => {
  app.disable('x-powered-by');
  app.set('trust proxy', 1);

  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' }
    })
  );

  app.use(
    cors({
      origin(origin, callback) {
        if (!origin || env.corsOrigins.length === 0 || env.corsOrigins.includes(origin)) {
          callback(null, true);
          return;
        }
        callback(new Error('CORS origin blocked'));
      },
      credentials: true
    })
  );

  app.use(
    rateLimit({
      windowMs: env.rateLimit.windowMs,
      max: env.rateLimit.max,
      standardHeaders: true,
      legacyHeaders: false
    })
  );

  app.use(compression());
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: false, limit: '1mb' }));
  app.use(pinoHttp({ logger }));
};

