import path from 'node:path';
import { defineConfig, devices } from '@playwright/test';
import { PW_ENV } from './playwright/config/env';

const region = process.env.PW_REPORT_REGION || 'all';

export default defineConfig({
  testDir: './playwright',
  testMatch: /.*\.spec\.ts$/,
  fullyParallel: false,
  forbidOnly: PW_ENV.isCI,
  retries: PW_ENV.isCI ? 1 : 0,
  workers: PW_ENV.isCI ? 2 : 1,
  timeout: 60_000,
  expect: {
    timeout: 15_000,
  },
  outputDir: path.join('test-results', region),
  reporter: [
    ['list'],
    ['html', { outputFolder: path.join('playwright-report', region), open: 'never' }],
    ['json', { outputFile: path.join('playwright-report', region, 'results.json') }],
  ],
  use: {
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
    video: PW_ENV.videoMode,
    actionTimeout: 15_000,
    navigationTimeout: 45_000,
  },
  projects: [
    {
      name: 'backend',
      testDir: './playwright/backend',
      use: {
        baseURL: PW_ENV.backendUrl,
      },
    },
    {
      name: 'admin',
      testDir: './playwright/admin',
      use: {
        ...devices['Desktop Chrome'],
        baseURL: PW_ENV.adminUrl,
        viewport: { width: 1280, height: 800 },
      },
    },
    {
      name: 'staff',
      testDir: './playwright/staff',
      use: {
        ...devices['Desktop Chrome'],
        baseURL: PW_ENV.staffUrl,
        viewport: { width: 412, height: 915 },
      },
    },
    {
      name: 'client',
      testDir: './playwright/client',
      use: {
        ...devices['Desktop Chrome'],
        baseURL: PW_ENV.clientUrl,
        viewport: { width: 412, height: 915 },
      },
    },
  ],
});
