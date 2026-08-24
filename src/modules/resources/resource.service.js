import { query } from '../../config/db.js';
import { ApiError } from '../../utils/errors.js';
import { id } from '../../utils/ids.js';

const jsonFields = new Set(['metadata', 'payload', 'layout', 'settings', 'setting_value', 'syllabus_scope']);

const cleanBody = (config, body) => {
  const output = {};
  for (const field of config.fields) {
    if (Object.prototype.hasOwnProperty.call(body, field)) {
      const value = body[field];
      output[field] = jsonFields.has(field) && value !== null && typeof value !== 'string' ? JSON.stringify(value) : value;
    }
  }
  return output;
};

const columns = (config, body) => Object.keys(cleanBody(config, body));

export const list = async (config, userId, { limit = 50, offset = 0, since } = {}) => {
  const safeLimit = Math.min(Number(limit) || 50, 200);
  const safeOffset = Math.max(Number(offset) || 0, 0);
  const where = ['user_id = :userId'];
  const params = { userId, limit: safeLimit, offset: safeOffset };

  if (since) {
    where.push('updated_at >= :since');
    params.since = since;
  }

  return query(
    `SELECT *
     FROM ${config.table}
     WHERE ${where.join(' AND ')}
     ORDER BY updated_at DESC, created_at DESC
     LIMIT :limit OFFSET :offset`,
    params
  );
};

export const get = async (config, userId, resourceId) => {
  const rows = await query(`SELECT * FROM ${config.table} WHERE id = :id AND user_id = :userId LIMIT 1`, {
    id: resourceId,
    userId
  });
  if (!rows.length) throw new ApiError(404, 'Resource not found');
  return rows[0];
};

export const create = async (config, userId, body) => {
  const row = cleanBody(config, body);
  const rowId = id();
  const fieldNames = columns(config, body);
  const allColumns = ['id', 'user_id', ...fieldNames, 'created_at', 'updated_at'];
  const values = [':id', ':userId', ...fieldNames.map((field) => `:${field}`), 'NOW()', 'NOW()'];
  await query(
    `INSERT INTO ${config.table} (${allColumns.join(', ')}) VALUES (${values.join(', ')})`,
    { id: rowId, userId, ...row }
  );
  return get(config, userId, rowId);
};

export const update = async (config, userId, resourceId, body) => {
  const row = cleanBody(config, body);
  const fieldNames = Object.keys(row);
  if (!fieldNames.length) throw new ApiError(422, 'No valid fields supplied');

  await query(
    `UPDATE ${config.table}
     SET ${fieldNames.map((field) => `${field} = :${field}`).join(', ')}, updated_at = NOW()
     WHERE id = :id AND user_id = :userId`,
    { id: resourceId, userId, ...row }
  );

  return get(config, userId, resourceId);
};

export const remove = async (config, userId, resourceId) => {
  const existing = await get(config, userId, resourceId);
  await query(`DELETE FROM ${config.table} WHERE id = :id AND user_id = :userId`, {
    id: resourceId,
    userId
  });
  return existing;
};

