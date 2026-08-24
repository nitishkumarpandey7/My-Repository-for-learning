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
  multipleStatements: true
});

try {
  const migrationDir = join(process.cwd(), 'migrations');
  const files = (await readdir(migrationDir)).filter((file) => file.endsWith('.sql')).sort();

  for (const file of files) {
    const sql = await readFile(join(migrationDir, file), 'utf8');
    logger.info(`Running migration ${file}`);
    await connection.query(sql);
  }

  logger.info('Migrations completed');
} finally {
  await connection.end();
}

