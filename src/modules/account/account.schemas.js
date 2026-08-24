import { z } from 'zod';

export const profileSchema = z.object({
  body: z.object({
    fullName: z.string().max(120).optional(),
    avatarUrl: z.string().url().optional(),
    timezone: z.string().max(64).optional(),
    dateOfBirth: z.string().date().optional(),
    country: z.string().max(80).optional(),
    onboardingCompleted: z.boolean().optional(),
    analyticsOptIn: z.boolean().optional(),
    notificationOptIn: z.boolean().optional()
  })
});

export const deleteRequestSchema = z.object({
  body: z.object({
    reason: z.string().max(500).optional()
  })
});

export const confirmDeleteSchema = z.object({
  body: z.object({
    password: z.string().max(128).optional(),
    confirmation: z.literal('DELETE')
  })
});

