import { test, expect, loginViaApi, logoutViaApi } from '../fixtures/api.fixture';
import { PW_ENV } from '../config/env';

test.describe('Backend Public & Protected API (Playwright)', () => {
  // Test Case ID: SMP-342
  // Description: Kiểm tra endpoint công khai GET /news trả về HTTP 200 với success=true và danh sách dạng mảng.
  test('[SMP-342] GET /news công khai trả về HTTP 200 và danh sách mảng', async ({ request }) => {
    const res = await request.get('/news');
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data)).toBe(true);
  });

  // Test Case ID: SMP-343
  // Description: Kiểm tra các endpoint quản trị /admin/home/overview và /admin/positions khi không có token bị chặn 401.
  test('[SMP-343] Endpoint quản trị /admin/* không có token bị chặn 401', async ({ request }) => {
    const overviewRes = await request.get('/admin/home/overview');
    expect(overviewRes.status()).toBe(401);

    const positionsRes = await request.get('/admin/positions');
    expect(positionsRes.status()).toBe(401);
  });

  // Test Case ID: SMP-344
  // Description: Kiểm tra GET /reports/map khi không có token bị chặn HTTP 401.
  test('[SMP-344] GET /reports/map không có token trả về 401', async ({ request }) => {
    const res = await request.get('/reports/map?min_lat=10.7&max_lat=10.9&min_lng=106.6&max_lng=106.8');
    expect(res.status()).toBe(401);
  });

  // Test Case ID: SMP-345
  // Description: Kiểm tra RBAC: tài khoản Client từ biến môi trường gọi GET /admin/home/overview bị chặn 403 Forbidden.
  test('[SMP-345] Client gọi GET /admin/home/overview bị chặn quyền 403', async ({ request }) => {
    const creds = PW_ENV.getCredentials('client');
    test.skip(!creds, 'Chưa cấu hình PW_CLIENT_EMAIL / PW_CLIENT_PASSWORD trong biến môi trường');

    const { accessToken } = await loginViaApi(request, {
      email: creds!.email,
      password: creds!.password,
      role: 'client',
    });

    try {
      const res = await request.get('/admin/home/overview', {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      expect(res.status()).toBe(403);
    } finally {
      await logoutViaApi(request, accessToken);
    }
  });
});
