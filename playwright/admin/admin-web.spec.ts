import { test, expect } from '@playwright/test';
import { PW_ENV } from '../config/env';
import { bootFlutterWeb, fillFlutterInput, getSemanticText } from '../fixtures/flutter-web.fixture';

test.describe('Flutter Admin Web Automation (Playwright)', () => {
  // Test Case ID: SMP-346
  // Description: Kiểm tra khởi chạy Flutter Admin Web trên Desktop (1280x800), điều hướng /login và hiển thị đầy đủ màn hình đăng nhập.
  test('[SMP-346] Boot Flutter Admin Web (Desktop) và hiển thị màn hình đăng nhập', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    const { pageErrors } = await bootFlutterWeb(page, '/', { expectedUrlPart: '/login' });

    expect(pageErrors, `Lỗi runtime trên browser: ${pageErrors.join('; ')}`).toEqual([]);
    await expect(page).toHaveTitle(/SmartSpace Admin/i);

    const semantics = await getSemanticText(page);
    expect(semantics).toContain('Chào mừng trở lại');
    await expect(page.getByRole('button', { name: 'Đăng nhập' })).toBeVisible();
  });

  // Test Case ID: SMP-347
  // Description: Kiểm tra Flutter Admin Web hiển thị responsive trên màn hình hẹp Mobile (390x844) không lỗi runtime.
  test('[SMP-347] Màn hình đăng nhập Flutter Admin Web responsive trên Mobile (390x844)', async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    const { pageErrors } = await bootFlutterWeb(page, '/', { expectedUrlPart: '/login' });

    expect(pageErrors).toEqual([]);
    await expect(page.getByRole('button', { name: 'Đăng nhập' })).toBeVisible();
    expect(await page.getByRole('textbox').count()).toBeGreaterThanOrEqual(2);
  });

  // Test Case ID: SMP-348
  // Description: Kiểm tra nhấn nút Đăng nhập khi bỏ trống email và mật khẩu trên Admin Web hiển thị cảnh báo validation.
  test('[SMP-348] Validate form đăng nhập Admin Web khi bỏ trống Email và Mật khẩu', async ({ page }) => {
    await bootFlutterWeb(page, '/', { expectedUrlPart: '/login' });

    await page.getByRole('button', { name: 'Đăng nhập' }).click();
    await expect
      .poll(() => getSemanticText(page), { timeout: 10_000 })
      .toContain('Vui lòng nhập email và mật khẩu');
    expect(page.url()).toContain('/login');
  });

  // Test Case ID: SMP-349
  // Description: Kiểm tra nhấn Quên mật khẩu? trên Admin Web mở màn hình khôi phục mật khẩu (/forgot-password) qua GoRouter.
  test('[SMP-349] Điều hướng từ Đăng nhập sang Quên mật khẩu trên Admin Web', async ({ page }) => {
    await bootFlutterWeb(page, '/', { expectedUrlPart: '/login' });

    await page.getByRole('button', { name: 'Quên mật khẩu?' }).click();
    // AdminLoginScreen dùng context.push (URL mặc định không đổi trên web); xác minh màn hình Quên mật khẩu đã render
    await expect
      .poll(() => getSemanticText(page), { timeout: 15_000 })
      .toContain('Nhập email của bạn để nhận mã OTP');
    await expect(page.getByRole('button', { name: 'Quay lại đăng nhập' })).toBeVisible();
  });

  // Test Case ID: SMP-350
  // Description: Kiểm tra luồng E2E đăng nhập Admin Web bằng tài khoản từ biến môi trường và điều hướng vào /home.
  test('[SMP-350] Luồng E2E đăng nhập Admin Web thành công vào trang chủ /home', async ({ page }) => {
    const creds = PW_ENV.getCredentials('admin');
    test.skip(!creds, 'Chưa cấu hình PW_ADMIN_EMAIL / PW_ADMIN_PASSWORD trong biến môi trường');

    await bootFlutterWeb(page, '/', { expectedUrlPart: '/login' });

    const textboxes = page.getByRole('textbox');
    await fillFlutterInput(page, textboxes.nth(0), creds!.email);
    await fillFlutterInput(page, textboxes.nth(1), creds!.password);

    await page.getByRole('button', { name: 'Đăng nhập' }).click();
    await expect.poll(() => page.url(), { timeout: 30_000 }).toContain('/home');
  });
});
