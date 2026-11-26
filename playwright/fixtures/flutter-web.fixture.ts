import { expect, type Locator, type Page } from '@playwright/test';

export interface FlutterBootResult {
  pageErrors: string[];
}

/**
 * Kích hoạt accessibility/semantics tree trên Flutter Web (CanvasKit / Skwasm)
 * để Playwright có thể truy vấn và tương tác ổn định với các widget qua role/label/text.
 */
export async function enableFlutterSemantics(page: Page, timeoutMs = 30_000): Promise<void> {
  const deadline = Date.now() + timeoutMs;

  while (Date.now() < deadline) {
    const ready = await page.evaluate(() => {
      const roots: Array<Document | ShadowRoot> = [document];
      for (const host of document.querySelectorAll('flt-glass-pane, flutter-view')) {
        if (host.shadowRoot) {
          roots.push(host.shadowRoot);
        }
      }

      for (const root of roots) {
        if (root.querySelector('flt-semantics-host flt-semantics')) {
          return true;
        }
      }

      for (const root of roots) {
        const placeholder = root.querySelector('flt-semantics-placeholder') as HTMLElement | null;
        if (placeholder) {
          placeholder.focus();
          placeholder.click();
          placeholder.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
          return false;
        }
      }
      return false;
    });

    if (ready) {
      return;
    }
    await page.waitForTimeout(250);
  }

  throw new Error('Không thể kích hoạt Flutter Web semantics tree (<flt-semantics-host>) trong thời gian chờ.');
}

/**
 * Mở ứng dụng Flutter Web, đợi SplashScreen hoàn tất điều hướng (nếu có expectedPath)
 * và bật Flutter semantics tree.
 */
export async function bootFlutterWeb(
  page: Page,
  url: string,
  options?: { expectedUrlPart?: string; timeoutMs?: number },
): Promise<FlutterBootResult> {
  const pageErrors: string[] = [];
  page.on('pageerror', (err) => {
    pageErrors.push(err.message);
  });

  await page.goto(url, { waitUntil: 'domcontentloaded' });
  await page.locator('flutter-view, flt-glass-pane').first().waitFor({ state: 'attached', timeout: 45_000 });

  if (options?.expectedUrlPart) {
    await expect
      .poll(() => page.url(), {
        timeout: options.timeoutMs ?? 30_000,
        message: `Chờ URL chứa "${options.expectedUrlPart}"`,
      })
      .toContain(options.expectedUrlPart);
  }

  await enableFlutterSemantics(page, options?.timeoutMs ?? 30_000);
  return { pageErrors };
}

/**
 * Điền giá trị vào ô nhập liệu Flutter Web theo semantic role/label.
 */
export async function fillFlutterInput(page: Page, locator: Locator, value: string): Promise<void> {
  await locator.first().waitFor({ state: 'visible', timeout: 15_000 });
  await locator.first().click();
  await page.waitForTimeout(100);

  const focusedInput = page.locator('input:focus, textarea:focus').first();
  if ((await focusedInput.count()) > 0) {
    await focusedInput.fill(value);
    return;
  }

  await page.keyboard.press('ControlOrMeta+A');
  await page.keyboard.insertText(value);
}

/**
 * Thu thập toàn bộ text và aria-label từ semantics tree để hỗ trợ kiểm tra/chẩn đoán.
 */
export async function getSemanticText(page: Page): Promise<string> {
  return page.evaluate(() => {
    const texts: string[] = [];
    const collect = (root: Document | ShadowRoot) => {
      for (const el of root.querySelectorAll('flt-semantics')) {
        const label = el.getAttribute('aria-label');
        if (label) texts.push(label);
        const text = el.textContent?.trim();
        if (text) texts.push(text);
      }
    };
    collect(document);
    for (const host of document.querySelectorAll('flt-glass-pane, flutter-view')) {
      if (host.shadowRoot) collect(host.shadowRoot);
    }
    return texts.join(' | ');
  });
}
