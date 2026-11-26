import crypto from 'node:crypto';
import { test as base, expect, type APIRequestContext } from '@playwright/test';
import type { TestRole } from '../config/env';

export { expect };
export const test = base;

export interface ApiLoginResult {
  accessToken: string;
  refreshToken: string;
  registrationStatus?: string;
}

export async function loginViaApi(
  request: APIRequestContext,
  params: { email: string; password: string; role: TestRole },
): Promise<ApiLoginResult> {
  const deviceId = `pw-${params.role}-${crypto.randomUUID()}`;
  const res = await request.post('/auth/login', {
    data: {
      email: params.email,
      password: params.password,
      deviceId,
      deviceName: 'Playwright Runner',
      platform: 'web',
      role: params.role,
      rememberMe: false,
    },
  });
  expect(res.status(), `Đăng nhập API (${params.role}) thất bại`).toBe(200);
  const body = await res.json();
  expect(body.success).toBe(true);
  expect(body.data?.access_token).toBeTruthy();
  return {
    accessToken: body.data.access_token,
    refreshToken: body.data.refresh_token,
    registrationStatus: body.data.registration_status,
  };
}

export async function logoutViaApi(request: APIRequestContext, accessToken: string): Promise<void> {
  if (!accessToken) return;
  await request.post('/auth/logout', {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });
}
