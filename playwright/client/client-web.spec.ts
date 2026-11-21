import { test, expect } from '@playwright/test';
import { PW_ENV } from '../config/env';
import { bootFlutterWeb, fillFlutterInput, getSemanticText } from '../fixtures/flutter-web.fixture';

test.describe('Flutter Client Web Automation (Playwright)', () => {
  // Test Case ID: SMP-356
  // Description: Kiểm tra khởi chạy Flutter Client Web, điều hướng /login và hiển thị đầy đủ các thành phần đăng nhập.
  test('[SMP-356] Boot Flutter Client Web và hiển thị màn hình đăng nhập Client', async ({ page }) => {
    const { pageErrors } = await bootFlutterWeb(page, '/', { expectedUrlPart: '/login' });

    expect(pageErrors, `Lỗi runtime trên browser: ${pageErrors.join('; ')}`).toEqual([]);
    await expect(page).toHaveTitle(/SmartSpace/i);

    const semantics = await getSemanticText(page);
    expect(semantics).toContain('Chào mừng trở lại');
    await expect(page.getByRole('button', { name: 'Đăng nhập', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Đăng ký' })).toBeVisible();
  });

  // Test Case ID: SMP-357
  // Description: Kiểm tra nhấn Đăng nhập khi bỏ trống email và mật khẩu trên Client Web hiển thị thông báo validation.
  test('[SMP-357] Validate form đăng nhập Client Web khi bỏ trống Email và Mật khẩu', async ({ page }) => {
    await bootFlutterWeb(page, '/', { expectedUrlPart: '/login' });

    await page.getByRole('button', { name: 'Đăng nhập', exact: true }).click();
    await expect
      .poll(() => getSemanticText(page), { timeout: 10_000 })
      .toContain('Vui lòng nhập email và mật khẩu');
    expect(page.url()).toContain('/login');
  });

  // Test Case ID: SMP-358
  // Description: Kiểm tra nhấn Đăng ký trên màn hình đăng nhập Client Web mở màn hình đăng ký Email (/register-email) qua GoRouter.
  test('[SMP-358] Điều hướng từ Đăng nhập sang màn hình Đăng ký Email trên Client Web', async ({ page }) => {
    await bootFlutterWeb(page, '/', { expectedUrlPart: '/login' });

    await page.getByRole('button', { name: 'Đăng ký' }).click();
    // MobileLoginScreen dùng context.push (URL mặc định không đổi trên web); xác minh màn hình Đăng ký Email đã render
    await expect
      .poll(() => getSemanticText(page), { timeout: 15_000 })
      .toContain('Địa chỉ email của bạn là gì?');
    await expect(page.getByRole('button', { name: 'Tiếp tục' })).toBeVisible();
  });

  // Test Case ID: SMP-359
  // Description: Kiểm tra nhấn Quên mật khẩu? trên màn hình đăng nhập Client Web mở màn hình khôi phục mật khẩu qua GoRouter.
  test('[SMP-359] Điều hướng từ Đăng nhập sang Quên mật khẩu trên Client Web', async ({ page }) => {
    await bootFlutterWeb(page, '/', { expectedUrlPart: '/login' });

    await page.getByRole('button', { name: 'Quên mật khẩu?' }).click();
    await expect
      .poll(() => getSemanticText(page), { timeout: 15_000 })
      .toContain('Nhập email của bạn để nhận mã OTP');
    await expect(page.getByRole('button', { name: 'Đặt lại mật khẩu' })).toBeVisible();
  });

  // Test Case ID: SMP-360
  // Description: Kiểm tra luồng E2E đăng nhập Client Web bằng tài khoản từ biến môi trường và điều hướng vào /home.
  test('[SMP-360] Luồng E2E đăng nhập Client Web thành công vào trang chủ /home', async ({ page }) => {
    const creds = PW_ENV.getCredentials('client');
    test.skip(!creds, 'Chưa cấu hình PW_CLIENT_EMAIL / PW_CLIENT_PASSWORD trong biến môi trường');

    await bootFlutterWeb(page, '/', { expectedUrlPart: '/login' });

    const textboxes = page.getByRole('textbox');
    await fillFlutterInput(page, textboxes.nth(0), creds!.email);
    await fillFlutterInput(page, textboxes.nth(1), creds!.password);

    await page.getByRole('button', { name: 'Đăng nhập', exact: true }).click();
    await expect.poll(() => page.url(), { timeout: 30_000 }).toContain('/home');
  });
});
