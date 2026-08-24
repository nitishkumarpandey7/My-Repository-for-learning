import { z } from 'zod';

const message = z.object({
  role: z.enum(['system', 'user', 'assistant']),
  content: z.string().min(1).max(12000)
});

export const chatSchema = z.object({
  body: z.object({
    conversationId: z.string().max(80).optional(),
    provider: z.enum(['local', 'gemini', 'openrouter', 'ollama', 'lmstudio']).optional(),
    messages: z.array(message).min(1).max(40),
    context: z
      .object({
        habits: z.array(z.any()).optional(),
        tasks: z.array(z.any()).optional(),
        finance: z.array(z.any()).optional(),
        study: z.array(z.any()).optional(),
        mood: z.any().optional()
      })
      .optional()
  })
});

export const recommendationSchema = z.object({
  body: z.object({
    domain: z.enum(['habits', 'bad_habits', 'finance', 'study', 'tasks', 'fitness', 'burnout', 'weekly_report']),
    facts: z.record(z.string(), z.any()).default({})
  })
});
