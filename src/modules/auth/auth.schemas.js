import { z } from 'zod';

const email = z.string().email().max(190);
const password = z.string().min(8).max(128);

export const registerSchema = z.object({
  body: z.object({
    email,
    password,
    displayName: z.string().min(1).max(120).optional(),
    timezone: z.string().max(64).default('Asia/Calcutta')
  })
});

export const loginSchema = z.object({
  body: z.object({
    email,
    password,
    rememberMe: z.boolean().default(true),
    device: z
      .object({
        deviceId: z.string().max(120).optional(),
        platform: z.string().max(80).optional(),
        model: z.string().max(120).optional(),
        appVersion: z.string().max(40).optional(),
        fcmToken: z.string().max(512).optional()
      })
      .optional()
  })
});

export const refreshSchema = z.object({
  body: z.object({
    refreshToken: z.string().min(20)
  })
});

export const firebaseLoginSchema = z.object({
  body: z.object({
    idToken: z.string().min(20),
    provider: z.enum(['firebase', 'google', 'phone']).default('firebase'),
    device: z
      .object({
        deviceId: z.string().max(120).optional(),
        platform: z.string().max(80).optional(),
        model: z.string().max(120).optional(),
        appVersion: z.string().max(40).optional(),
        fcmToken: z.string().max(512).optional()
      })
      .optional()
  })
});

export const forgotPasswordSchema = z.object({
  body: z.object({
    email
  })
});

export const biometricSchema = z.object({
  body: z.object({
    enabled: z.boolean(),
    deviceId: z.string().min(1).max(120)
  })
});

