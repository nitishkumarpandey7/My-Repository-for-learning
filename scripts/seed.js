import { readdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';
import mysql from 'mysql2/promise';
import { env } from '../src/config/env.js';
import { logger } from '../src/config/logger.js';

const connection = await mysql.createConnection({
  host: env.db.host,
  port: env.db.port,
  user: env.db.user,
  password: env.db.password,
  database: env.db.database,
  multipleStatements: true
});

try {
  const seedDir = join(process.cwd(), 'seeds');
  const files = (await readdir(seedDir)).filter((file) => file.endsWith('.sql')).sort();

  for (const file of files) {
    const sql = await readFile(join(seedDir, file), 'utf8');
    logger.info(`Running seed ${file}`);
    await connection.query(sql);
  }

  logger.info('Seeds completed');
} finally {
  await connection.end();
}

