import * as service from './ai.service.js';
import { asyncHandler } from '../../utils/errors.js';

export const chat = asyncHandler(async (req, res) => {
  const data = await service.chat({ userId: req.user.id, body: req.validated.body });
  res.json({ ok: true, data });
});

export const streamChat = asyncHandler(async (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  const data = await service.chat({ userId: req.user.id, body: req.validated.body });
  for (const word of data.content.split(/(\s+)/)) {
    res.write(`data: ${JSON.stringify({ delta: word })}\n\n`);
  }
  res.write(`data: ${JSON.stringify({ done: true, provider: data.provider, conversationId: data.conversationId })}\n\n`);
  res.end();
});

export const recommendation = asyncHandler(async (req, res) => {
  const data = await service.recommendation({
    userId: req.user.id,
    domain: req.validated.body.domain,
    facts: req.validated.body.facts
  });
  res.json({ ok: true, data });
});

export const conversations = asyncHandler(async (req, res) => {
  const data = await service.conversations(req.user.id);
  res.json({ ok: true, data });
});

