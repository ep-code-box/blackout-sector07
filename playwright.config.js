const { defineConfig, devices } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './tests/e2e',
  timeout: 90 * 1000,
  expect: { timeout: 10000 },
  fullyParallel: false,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: process.env.CI ? 'github' : 'list',
  use: {
    headless: process.env.CI ? true : false, // 로컬에선 기본적으로 창을 띄움
    actionTimeout: 0,
    trace: 'on-first-retry',
    viewport: { width: 1280, height: 720 },
  },
  projects: [
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
  ],
  webServer: {
    command: 'npm run serve:web',
    port: 8080,
    reuseExistingServer: !process.env.CI,
  },
});
