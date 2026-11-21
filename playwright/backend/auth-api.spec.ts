import { test, expect, loginViaApi, logoutViaApi } from '../fixtures/api.fixture';
import { PW_ENV } from '../config/env';

test.describe('Backend Auth & Core API (Playwright)', () => {
  // Test Case ID: SMP-336
  // Description: Kiểm tra endpoint GET /v3/api-docs trả về HTTP 200 và OpenAPI JSON hợp lệ làm health check Backend.
  test('[SMP-336] GET /v3/api-docs trả về HTTP 200 và tài liệu OpenAPI hợp lệ', async ({ request }) => {
    const res = await request.get('/v3/api-docs');
    expect(res.status()).toBe(200);
    const json = await res.json();
    expect(json.openapi).toBeTruthy();
    expect(json.paths).toBeTruthy();
  });

  // Test Case ID: SMP-337
  // Description: Kiểm tra GET /auth/me khi không có Bearer token bị từ chối với HTTP 401.
  test('[SMP-337] GET /auth/me không có token bị từ chối 401', async ({ request }) => {
    const res = await request.get('/auth/me');
    expect(res.status()).toBe(401);
  });

  // Test Case ID: SMP-338
  // Description: Kiểm tra POST /auth/login với payload rỗng trả về HTTP 400 Bad Request do lỗi validation.
  test('[SMP-338] POST /auth/login với payload rỗng trả về 400', async ({ request }) => {
    const res = await request.post('/auth/login', {
      data: {},
    });
    expect(res.status()).toBe(400);
  });

  // Test Case ID: SMP-339
  // Description: Kiểm tra POST /auth/login với email không tồn tại bị từ chối (400/401) và success=false.
  test('[SMP-339] POST /auth/login với tài khoản không tồn tại bị từ chối', async ({ request }) => {
    const res = await request.post('/auth/login', {
      data: {
        email: 'nonexistent-pw@smartspace.invalid',
        password: 'invalid-password-value',
        deviceId: 'pw-invalid-login-check',
        deviceName: 'Playwright Runner',
        platform: 'web',
        role: 'client',
        rememberMe: false,
      },
    });
    expect([400, 401]).toContain(res.status());
    const body = await res.json();
    expect(body.success).toBe(false);
  });

  // Test Case ID: SMP-340
  // Description: Kiểm tra POST /auth/logout khi thiếu header Authorization trả về HTTP 401.
  test('[SMP-340] POST /auth/logout thiếu header Authorization trả về 401', async ({ request }) => {
    const res = await request.post('/auth/logout');
    expect(res.status()).toBe(401);
  });

  // Test Case ID: SMP-341
  // Description: Kiểm tra luồng đăng nhập Admin -> GET /auth/me -> POST /auth/logout qua API với thông tin từ biến môi trường.
  test('[SMP-341] Luồng đăng nhập Admin, gọi /auth/me và đăng xuất thành công', async ({ request }) => {
    const creds = PW_ENV.getCredentials('admin');
    test.skip(!creds, 'Chưa cấu hình PW_ADMIN_EMAIL / PW_ADMIN_PASSWORD trong biến môi trường');

    const { accessToken } = await loginViaApi(request, {
      email: creds!.email,
      password: creds!.password,
      role: 'admin',
    });

    try {
      const meRes = await request.get('/auth/me', {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      expect(meRes.status()).toBe(200);
      const meBody = await meRes.json();
      expect(meBody.success).toBe(true);
      expect(meBody.data?.email).toBe(creds!.email);
    } finally {
      await logoutViaApi(request, accessToken);
    }
  });
});
