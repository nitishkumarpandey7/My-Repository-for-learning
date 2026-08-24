import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';

export const signAccessToken = (user) =>
  jwt.sign(
    {
      sub: user.id,
      email: user.email,
      role: user.role ?? 'user',
      type: 'access'
    },
    env.jwt.accessSecret,
    { expiresIn: env.jwt.accessExpiresIn }
  );

export const signRefreshToken = (user) =>
  jwt.sign(
    {
      sub: user.id,
      type: 'refresh'
    },
    env.jwt.refreshSecret,
    { expiresIn: env.jwt.refreshExpiresIn }
  );

export const verifyAccessToken = (token) =>
  jwt.verify(token, env.jwt.accessSecret);

export const verifyRefreshToken = (token) =>
  jwt.verify(token, env.jwt.refreshSecret);

