import mysql from 'mysql2/promise';
import { env } from '../src/config/env.js';

const sql = process.argv.slice(2).join(' ').trim();

if (!sql) {
  console.error('Usage: npm run db:query -- "SELECT * FROM users LIMIT 5"');
  process.exit(1);
}

const connection = await mysql.createConnection({
  host: env.db.host,
  port: env.db.port,
  user: env.db.user,
  password: env.db.password,
  database: env.db.database,
  multipleStatements: false
});

try {
  const [rows] = await connection.execute(sql);
  console.table(rows);
} finally {
  await connection.end();
}
