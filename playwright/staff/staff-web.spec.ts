import { test, expect } from '@playwright/test';
import { PW_ENV } from '../config/env';
import { bootFlutterWeb, fillFlutterInput, getSemanticText } from '../fixtures/flutter-web.fixture';

test.describe('Flutter Staff Web Automation (Playwright)', () => {
  // Test Case ID: SMP-351
  // Description: Kiểm tra khởi chạy Flutter Staff Web, redirect sang /#/login và hiển thị cổng nhân viên.
  test('[SMP-351] Boot Flutter Staff Web và hiển thị màn hình đăng nhập nhân viên', async ({ page }) => {
    const { pageErrors } = await bootFlutterWeb(page, '/', { expectedUrlPart: '/login' });

    expect(pageErrors, `Lỗi runtime trên browser: ${pageErrors.join('; ')}`).toEqual([]);
    await expect(page).toHaveTitle(/SmartSpace Staff/i);

    const semantics = await getSemanticText(page);
    expect(semantics).toContain('Đăng nhập nhân viên');
    await expect(page.getByRole('button', { name: 'Đăng nhập' })).toBeVisible();
  });

  // Test Case ID: SMP-352
  // Description: Kiểm tra nhấn Đăng nhập khi bỏ trống email và mật khẩu trên Staff Web hiển thị thông báo validation.
  test('[SMP-352] Validate form đăng nhập Staff Web khi bỏ trống thông tin', async ({ page }) => {
    await bootFlutterWeb(page, '/', { expectedUrlPart: '/login' });

    await page.getByRole('button', { name: 'Đăng nhập' }).click();
    await expect
      .poll(() => getSemanticText(page), { timeout: 10_000 })
      .toContain('Vui lòng nhập email và mật khẩu');
    expect(page.url()).toContain('/login');
  });

  // Test Case ID: SMP-353
  // Description: Kiểm tra đăng nhập sai tài khoản trên Staff Web gọi API thật, hiển thị lỗi và giữ nguyên trang login.
  test('[SMP-353] Đăng nhập Staff Web với tài khoản không tồn tại hiển thị lỗi từ Backend', async ({ page }) => {
    await bootFlutterWeb(page, '/', { expectedUrlPart: '/login' });

    const textboxes = page.getByRole('textbox');
    await fillFlutterInput(page, textboxes.nth(0), 'nonexistent-staff@smartspace.invalid');
    await fillFlutterInput(page, textboxes.nth(1), 'invalid-password-value');

    const [loginRes] = await Promise.all([
      page.waitForResponse((res) => res.url().includes('/auth/login') && res.request().method() === 'POST', {
        timeout: 20_000,
      }),
      page.getByRole('button', { name: 'Đăng nhập' }).click(),
    ]);

    expect([400, 401]).toContain(loginRes.status());
    await page.waitForTimeout(500);
    expect(page.url()).toContain('/login');
  });

  // Test Case ID: SMP-354
  // Description: Kiểm tra mở drawer cài đặt (ngôn ngữ và giao diện) trên màn hình đăng nhập Staff Web.
  test('[SMP-354] Mở drawer cài đặt ngôn ngữ và giao diện trên Staff Web', async ({ page }) => {
    await bootFlutterWeb(page, '/', { expectedUrlPart: '/login' });

    // Nút IconButton(Icons.settings) nằm đầu màn hình đăng nhập Staff
    await page.getByRole('button').first().click();
    await expect
      .poll(() => getSemanticText(page), { timeout: 10_000 })
      .toContain('Cài đặt');
  });

  // Test Case ID: SMP-355
  // Description: Kiểm tra luồng E2E đăng nhập Staff Web bằng tài khoản từ biến môi trường và điều hướng vào /#/home.
  test('[SMP-355] Luồng E2E đăng nhập Staff Web thành công vào trang chủ /home', async ({ page }) => {
    const creds = PW_ENV.getCredentials('staff');
    test.skip(!creds, 'Chưa cấu hình PW_STAFF_EMAIL / PW_STAFF_PASSWORD trong biến môi trường');

    await bootFlutterWeb(page, '/', { expectedUrlPart: '/login' });

    const textboxes = page.getByRole('textbox');
    await fillFlutterInput(page, textboxes.nth(0), creds!.email);
    await fillFlutterInput(page, textboxes.nth(1), creds!.password);

    await page.getByRole('button', { name: 'Đăng nhập' }).click();
    await expect.poll(() => page.url(), { timeout: 30_000 }).toContain('/home');
  });
});
