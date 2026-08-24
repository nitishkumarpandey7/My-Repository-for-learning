import mysql from 'mysql2/promise';
import { env } from './env.js';
import { logger } from './logger.js';

let pool;

export const getPool = () => {
  if (!pool) {
    pool = mysql.createPool({
      host: env.db.host,
      port: env.db.port,
      database: env.db.database,
      user: env.db.user,
      password: env.db.password,
      waitForConnections: true,
      connectionLimit: env.db.connectionLimit,
      queueLimit: 0,
      namedPlaceholders: true,
      enableKeepAlive: true,
      keepAliveInitialDelay: 0,
      timezone: 'Z'
    });

    pool.on?.('connection', () => logger.debug('MySQL connection opened'));
  }
  return pool;
};

export const query = async (sql, params = {}) => {
  const [rows] = await getPool().execute(sql, params);
  return rows;
};

export const transaction = async (handler) => {
  const connection = await getPool().getConnection();
  try {
    await connection.beginTransaction();
    const result = await handler(connection);
    await connection.commit();
    return result;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

export const pingDatabase = async () => {
  const [rows] = await getPool().query('SELECT 1 AS ok');
  return rows?.[0]?.ok === 1;
};

export const closePool = async () => {
  if (pool) {
    await pool.end();
    pool = undefined;
  }
};

