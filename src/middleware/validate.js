import { ApiError } from '../utils/errors.js';

export const validate = (schema) => (req, _res, next) => {
  const result = schema.safeParse({
    body: req.body,
    query: req.query,
    params: req.params
  });

  if (!result.success) {
    next(new ApiError(422, 'Validation failed', result.error.flatten()));
    return;
  }

  req.validated = result.data;
  next();
};

