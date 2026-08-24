import { getResource } from './resource.config.js';
import * as service from './resource.service.js';
import { ApiError, asyncHandler } from '../../utils/errors.js';

export const attachResource = (slug) => (req, _res, next) => {
  const config = getResource(slug);
  if (!config) return next(new ApiError(404, `Unknown resource: ${slug}`));
  req.resourceConfig = config;
  req.resourceSlug = slug;
  return next();
};

export const list = asyncHandler(async (req, res) => {
  const data = await service.list(req.resourceConfig, req.user.id, req.query);
  res.json({ ok: true, data, meta: { resource: req.resourceSlug } });
});

export const get = asyncHandler(async (req, res) => {
  const data = await service.get(req.resourceConfig, req.user.id, req.params.id);
  res.json({ ok: true, data });
});

export const create = asyncHandler(async (req, res) => {
  const data = await service.create(req.resourceConfig, req.user.id, req.body);
  res.status(201).json({ ok: true, data });
});

export const update = asyncHandler(async (req, res) => {
  const data = await service.update(req.resourceConfig, req.user.id, req.params.id, req.body);
  res.json({ ok: true, data });
});

export const remove = asyncHandler(async (req, res) => {
  const data = await service.remove(req.resourceConfig, req.user.id, req.params.id);
  res.json({ ok: true, data });
});

