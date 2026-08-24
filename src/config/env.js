import dotenv from 'dotenv';

dotenv.config();

const asInt = (value, fallback) => {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const splitList = (value) =>
  String(value ?? '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);

export const env = Object.freeze({
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: asInt(process.env.PORT, 8080),
  apiVersion: process.env.API_VERSION ?? 'v1',
  corsOrigins: splitList(process.env.CORS_ORIGIN),
  db: {
    host: process.env.DB_HOST ?? 'localhost',
    port: asInt(process.env.DB_PORT, 3306),
    database: process.env.DB_NAME ?? 'Nitish_db',
    user: process.env.DB_USER ?? 'root',
    password: process.env.DB_PASSWORD ?? 'Nitish1@',
    connectionLimit: asInt(process.env.DB_CONNECTION_LIMIT, 10)
  },
  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET ?? 'dev-access-secret',
    refreshSecret: process.env.JWT_REFRESH_SECRET ?? 'dev-refresh-secret',
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN ?? '15m',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN ?? '30d'
  },
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET
  },
  ai: {
    defaultProvider: process.env.AI_DEFAULT_PROVIDER ?? 'local',
    geminiApiKey: process.env.GEMINI_API_KEY,
    geminiModel: process.env.GEMINI_MODEL ?? 'gemini-1.5-flash',
    openRouterApiKey: process.env.OPENROUTER_API_KEY,
    openRouterModel: process.env.OPENROUTER_MODEL ?? 'google/gemma-2-9b-it:free',
    ollamaBaseUrl: process.env.OLLAMA_BASE_URL ?? 'http://localhost:11434',
    ollamaModel: process.env.OLLAMA_MODEL ?? 'llama3.2',
    lmStudioBaseUrl: process.env.LM_STUDIO_BASE_URL ?? 'http://localhost:1234',
    lmStudioModel: process.env.LM_STUDIO_MODEL ?? 'local-model'
  },
  rateLimit: {
    windowMs: asInt(process.env.RATE_LIMIT_WINDOW_MS, 15 * 60 * 1000),
    max: asInt(process.env.RATE_LIMIT_MAX, 300)
  }
});

