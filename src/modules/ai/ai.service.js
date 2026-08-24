import { GoogleGenerativeAI } from '@google/generative-ai';
import { env } from '../../config/env.js';
import { logger } from '../../config/logger.js';
import { query } from '../../config/db.js';
import { id } from '../../utils/ids.js';

const LIFEOS_SYSTEM_PROMPT = `You are LifeOS AI, a practical self-improvement coach.
Help with habits, bad habit recovery, study planning, finance, productivity, routines, and wellness.
Be encouraging, specific, non-judgmental, and action oriented.
Never present medical, financial, or legal guidance as professional advice.
Prefer simple plans, measurable next actions, recovery plans after setbacks, and free/open tools.`;

const lastUserText = (messages) => [...messages].reverse().find((message) => message.role === 'user')?.content ?? '';

const localCoach = ({ messages, context, domain }) => {
  const prompt = lastUserText(messages);
  const facts = context ? ` I can see ${Object.keys(context).filter((key) => context[key]).join(', ') || 'your current context'}.` : '';
  const domainLine = domain ? ` for ${domain.replace('_', ' ')}` : '';
  return [
    `Here is a focused LifeOS plan${domainLine}:`,
    '',
    `1. Pick the smallest action that proves momentum today: ${prompt.slice(0, 110) || 'complete one visible task'}.`,
    '2. Protect energy first: schedule a 25-minute focus block, a 5-minute reset, and one recovery habit.',
    '3. Track the result immediately so your streak, XP, and analytics stay honest.',
    '4. If you miss the target, log the trigger and restart with a smaller version within 24 hours.',
    '',
    `Smart signal:${facts} I would watch sleep, stress, overspending, skipped study sessions, and repeated snoozes as early burnout indicators.`
  ].join('\n');
};

const normalizeMessages = (messages) => {
  const withoutSystem = messages.filter((message) => message.role !== 'system');
  return [{ role: 'system', content: LIFEOS_SYSTEM_PROMPT }, ...withoutSystem];
};

const geminiChat = async (messages) => {
  if (!env.ai.geminiApiKey) throw new Error('Missing GEMINI_API_KEY');
  const genAI = new GoogleGenerativeAI(env.ai.geminiApiKey);
  const model = genAI.getGenerativeModel({ model: env.ai.geminiModel });
  const content = normalizeMessages(messages)
    .map((message) => `${message.role.toUpperCase()}: ${message.content}`)
    .join('\n\n');
  const result = await model.generateContent(content);
  return {
    provider: 'gemini',
    model: env.ai.geminiModel,
    content: result.response.text()
  };
};

const openRouterChat = async (messages) => {
  if (!env.ai.openRouterApiKey) throw new Error('Missing OPENROUTER_API_KEY');
  const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.ai.openRouterApiKey}`,
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://lifeosx.local',
      'X-Title': 'LifeOS X'
    },
    body: JSON.stringify({
      model: env.ai.openRouterModel,
      messages: normalizeMessages(messages)
    })
  });
  if (!response.ok) throw new Error(`OpenRouter failed: ${response.status}`);
  const payload = await response.json();
  return {
    provider: 'openrouter',
    model: env.ai.openRouterModel,
    content: payload.choices?.[0]?.message?.content ?? ''
  };
};

const ollamaChat = async (messages) => {
  const response = await fetch(`${env.ai.ollamaBaseUrl}/api/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: env.ai.ollamaModel,
      messages: normalizeMessages(messages),
      stream: false
    })
  });
  if (!response.ok) throw new Error(`Ollama failed: ${response.status}`);
  const payload = await response.json();
  return {
    provider: 'ollama',
    model: env.ai.ollamaModel,
    content: payload.message?.content ?? ''
  };
};

const lmStudioChat = async (messages) => {
  const response = await fetch(`${env.ai.lmStudioBaseUrl}/v1/chat/completions`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: env.ai.lmStudioModel,
      messages: normalizeMessages(messages),
      temperature: 0.6
    })
  });
  if (!response.ok) throw new Error(`LM Studio failed: ${response.status}`);
  const payload = await response.json();
  return {
    provider: 'lmstudio',
    model: env.ai.lmStudioModel,
    content: payload.choices?.[0]?.message?.content ?? ''
  };
};

const providerMap = {
  gemini: geminiChat,
  openrouter: openRouterChat,
  ollama: ollamaChat,
  lmstudio: lmStudioChat
};

export const runAi = async ({ provider, messages, context, domain }) => {
  const preferred = provider ?? env.ai.defaultProvider;
  if (preferred && preferred !== 'local' && providerMap[preferred]) {
    try {
      return await providerMap[preferred](messages);
    } catch (error) {
      logger.warn({ err: error, provider: preferred }, 'AI provider failed; using local fallback');
    }
  }

  return {
    provider: 'local',
    model: 'lifeos-rule-coach',
    content: localCoach({ messages, context, domain })
  };
};

export const saveChatTurn = async ({ userId, conversationId, request, response }) => {
  const safeConversationId = conversationId || id();
  const latestUser = lastUserText(request.messages);
  if (latestUser) {
    await query(
      `INSERT INTO AI_chat_history
        (id, user_id, conversation_id, role, content, provider, model, metadata, created_at, updated_at)
       VALUES (:id, :userId, :conversationId, 'user', :content, :provider, :model, :metadata, NOW(), NOW())`,
      {
        id: id(),
        userId,
        conversationId: safeConversationId,
        content: latestUser,
        provider: request.provider ?? null,
        model: null,
        metadata: JSON.stringify({ context: request.context ?? null })
      }
    );
  }

  await query(
    `INSERT INTO AI_chat_history
      (id, user_id, conversation_id, role, content, provider, model, metadata, created_at, updated_at)
     VALUES (:id, :userId, :conversationId, 'assistant', :content, :provider, :model, :metadata, NOW(), NOW())`,
    {
      id: id(),
      userId,
      conversationId: safeConversationId,
      content: response.content,
      provider: response.provider,
      model: response.model,
      metadata: JSON.stringify({ savedBy: 'ai.service' })
    }
  );

  return safeConversationId;
};

export const chat = async ({ userId, body }) => {
  const response = await runAi(body);
  const conversationId = await saveChatTurn({
    userId,
    conversationId: body.conversationId,
    request: body,
    response
  });
  return { conversationId, ...response };
};

export const recommendation = async ({ userId, domain, facts }) => {
  const messages = [
    {
      role: 'user',
      content: `Generate a concise recommendation for ${domain}. Facts: ${JSON.stringify(facts)}`
    }
  ];
  const response = await runAi({ messages, context: { facts }, domain });
  await query(
    `INSERT INTO analytics
      (id, user_id, metric_key, metric_value, metric_date, domain, metadata, created_at, updated_at)
     VALUES (:id, :userId, 'ai_recommendation', 1, CURRENT_DATE(), :domain, :metadata, NOW(), NOW())`,
    {
      id: id(),
      userId,
      domain,
      metadata: JSON.stringify({ provider: response.provider, model: response.model })
    }
  );
  return response;
};

export const conversations = (userId) =>
  query(
    `SELECT conversation_id AS conversationId, MAX(created_at) AS updatedAt, COUNT(*) AS messages
     FROM AI_chat_history
     WHERE user_id = :userId
     GROUP BY conversation_id
     ORDER BY updatedAt DESC
     LIMIT 40`,
    { userId }
  );

