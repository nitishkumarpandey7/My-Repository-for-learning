import { ApiError } from '../utils/errors.js';

export const notFound = (req, _res, next) => {
  next(new ApiError(404, `Route not found: ${req.method} ${req.originalUrl}`));
};

export const errorHandler = (error, req, res, _next) => {
  const statusCode = error instanceof ApiError ? error.statusCode : error.statusCode || 500;
  const payload = {
    ok: false,
    error: {
      message: statusCode === 500 ? 'Internal server error' : error.message,
      details: error.details
    }
  };

  req.log?.error({ err: error }, error.message);
  res.status(statusCode).json(payload);
};

