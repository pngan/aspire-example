import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright configuration for Aspire Example App
 * Supports testing against multiple environments:
 * - local: Development environment (localhost)
 * - ubuntu: Direct deployment (192.168.1.11:8080)
 * - production: Public domain with SSL (apps.nganfamily.com)
 */
export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html'],
    ['list']
  ],
  
  use: {
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    {
      name: 'local',
      use: { 
        ...devices['Desktop Chrome'],
        baseURL: process.env.LOCAL_BASE_URL || 'https://localhost:7024',
        ignoreHTTPSErrors: true, // Accept self-signed certificates in dev
      },
      testMatch: '**/*.spec.ts',
    },
    {
      name: 'ubuntu',
      use: { 
        ...devices['Desktop Chrome'],
        baseURL: process.env.UBUNTU_BASE_URL || 'http://192.168.1.11:8080',
      },
      testMatch: '**/*.spec.ts',
    },
    {
      name: 'production',
      use: { 
        ...devices['Desktop Chrome'],
        baseURL: process.env.PROD_BASE_URL || 'https://apps.nganfamily.com',
      },
      testMatch: '**/*.spec.ts',
    },
  ],

  /* Run your local dev server before starting the tests */
  // webServer: {
  //   command: 'dotnet run --project AspireApp/AspireApp.AppHost/AspireApp.AppHost.csproj',
  //   url: 'http://localhost:5273',
  //   reuseExistingServer: !process.env.CI,
  //   timeout: 120 * 1000,
  // },
});
