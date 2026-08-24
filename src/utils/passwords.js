import bcrypt from 'bcryptjs';

const ROUNDS = 12;

export const hashPassword = (password) => bcrypt.hash(password, ROUNDS);

export const verifyPassword = (password, hash) => bcrypt.compare(password, hash);

