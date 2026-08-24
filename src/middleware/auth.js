import { firebaseAuth } from '../config/firebase.js';
import { query } from '../config/db.js';
import { ApiError } from '../utils/errors.js';
import { verifyAccessToken } from '../utils/tokens.js';

const getBearerToken = (req) => {
  const header = req.headers.authorization ?? '';
  const [scheme, token] = header.split(' ');
  return /^Bearer$/i.test(scheme) ? token : null;
};

export const requireAuth = async (req, _res, next) => {
  try {
    const token = getBearerToken(req);
    if (!token) throw new ApiError(401, 'Missing bearer token');

    try {
      const decoded = verifyAccessToken(token);
      req.user = { id: decoded.sub, email: decoded.email, role: decoded.role, source: 'jwt' };
      return next();
    } catch {
      if (!firebaseAuth) throw new ApiError(401, 'Invalid token');
    }

    const decodedFirebase = await firebaseAuth.verifyIdToken(token);
    const users = await query(
      'SELECT id, email, role FROM users WHERE firebase_uid = :firebaseUid AND status = "active" LIMIT 1',
      { firebaseUid: decodedFirebase.uid }
    );
    if (!users.length) throw new ApiError(401, 'Firebase user is not linked');

    req.user = {
      id: users[0].id,
      email: users[0].email,
      role: users[0].role,
      source: 'firebase'
    };
    return next();
  } catch (error) {
    return next(error);
  }
};

export const optionalAuth = async (req, _res, next) => {
  const token = getBearerToken(req);
  if (!token) return next();
  return requireAuth(req, _res, next);
};

