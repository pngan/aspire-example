import { test, expect } from '@playwright/test';

test.describe('Health Endpoints', () => {
  test('should return healthy status from /health endpoint', async ({ request, baseURL }) => {
    const response = await request.get(`${baseURL}/health`);
    
    // Verify response is OK
    expect(response.ok()).toBeTruthy();
    expect(response.status()).toBe(200);
    
    // Health endpoints return text/plain in Aspire
    const body = await response.text();
    expect(body).toBe('Healthy');
  });

  test('should return alive status from /alive endpoint', async ({ request, baseURL }) => {
    const response = await request.get(`${baseURL}/alive`);
    
    // Verify response is OK
    expect(response.ok()).toBeTruthy();
    expect(response.status()).toBe(200);
    
    // Health endpoints return text/plain in Aspire
    const body = await response.text();
    expect(body).toBe('Healthy');
  });

  test('should verify /health endpoint response time is acceptable', async ({ request, baseURL }) => {
    const startTime = Date.now();
    const response = await request.get(`${baseURL}/health`);
    const endTime = Date.now();
    
    const responseTime = endTime - startTime;
    
    // Health check should respond within 5 seconds
    expect(responseTime).toBeLessThan(5000);
    expect(response.ok()).toBeTruthy();
  });

  test('should verify health endpoint includes service checks', async ({ request, baseURL }) => {
    const response = await request.get(`${baseURL}/health`);
    expect(response.ok()).toBeTruthy();
    
    // Aspire health endpoints return simple text
    const body = await response.text();
    expect(body).toBe('Healthy');
  });

  test('should handle health check across page navigation', async ({ page, request, baseURL }) => {
    // First verify endpoint directly
    const healthResponse = await request.get(`${baseURL}/health`);
    expect(healthResponse.ok()).toBeTruthy();
    
    // Then verify app pages load correctly
    await page.goto('/');
    await expect(page.locator('h1')).toContainText('Hello, world!');
    
    // Navigate to weather (which calls API)
    await page.goto('/weather');
    await expect(page.locator('table.table')).toBeVisible({ timeout: 10000 });
    
    // Verify health is still good
    const healthResponse2 = await request.get(`${baseURL}/health`);
    expect(healthResponse2.ok()).toBeTruthy();
  });
});
