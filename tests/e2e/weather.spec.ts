import { test, expect } from '@playwright/test';

test.describe('Weather Page', () => {
  test('should load the weather page', async ({ page }) => {
    await page.goto('/weather');
    
    // Verify page title
    await expect(page).toHaveTitle(/Weather/);
    
    // Verify main heading
    await expect(page.locator('h1')).toContainText('Weather');
    
    // Verify description
    await expect(page.locator('text=This component demonstrates showing data loaded from a backend API service')).toBeVisible();
  });

  test('should display weather forecast data from API', async ({ page }) => {
    await page.goto('/weather');
    
    // Wait for data to load (should see table instead of loading message)
    await expect(page.locator('text=Loading...')).not.toBeVisible({ timeout: 10000 });
    
    // Verify table is present
    await expect(page.locator('table.table')).toBeVisible();
    
    // Verify table headers
    await expect(page.locator('thead th:has-text("Date")')).toBeVisible();
    await expect(page.locator('thead th[aria-label="Temperature in Celsius"]')).toBeVisible();
    await expect(page.locator('thead th[aria-label="Temperature in Fahrenheit"]')).toBeVisible();
    await expect(page.locator('thead th:has-text("Summary")')).toBeVisible();
  });

  test('should display multiple weather forecast rows', async ({ page }) => {
    await page.goto('/weather');
    
    // Wait for table to load
    await expect(page.locator('table.table')).toBeVisible({ timeout: 10000 });
    
    // Verify at least one forecast row exists
    const rows = page.locator('tbody tr');
    await expect(rows).not.toHaveCount(0);
    
    // Verify first row has all cells
    const firstRow = rows.first();
    await expect(firstRow.locator('td').nth(0)).not.toBeEmpty(); // Date
    await expect(firstRow.locator('td').nth(1)).not.toBeEmpty(); // Temp C
    await expect(firstRow.locator('td').nth(2)).not.toBeEmpty(); // Temp F
    await expect(firstRow.locator('td').nth(3)).not.toBeEmpty(); // Summary
  });

  test('should display valid temperature data', async ({ page }) => {
    await page.goto('/weather');
    
    // Wait for table
    await expect(page.locator('table.table')).toBeVisible({ timeout: 10000 });
    
    // Get first temperature values
    const tempC = await page.locator('tbody tr').first().locator('td').nth(1).textContent();
    const tempF = await page.locator('tbody tr').first().locator('td').nth(2).textContent();
    
    // Verify temperatures are numeric
    expect(tempC).toMatch(/^-?\d+$/);
    expect(tempF).toMatch(/^-?\d+$/);
    
    // Verify Fahrenheit calculation is approximately correct (F = C * 9/5 + 32)
    const celsius = parseInt(tempC || '0');
    const fahrenheit = parseInt(tempF || '0');
    const expectedF = Math.round(celsius * 9/5 + 32);
    
    // Allow small rounding difference
    expect(Math.abs(fahrenheit - expectedF)).toBeLessThanOrEqual(1);
  });

  test('should verify API integration is working', async ({ page }) => {
    await page.goto('/weather');
    
    // Verify loading state appears first
    const loadingMessage = page.locator('text=Loading...');
    
    // Wait for loading to complete or skip if data loads too fast
    try {
      await expect(loadingMessage).toBeVisible({ timeout: 1000 });
    } catch {
      // Data loaded too fast, which is fine
    }
    
    // Verify data eventually loads
    await expect(page.locator('table.table')).toBeVisible({ timeout: 10000 });
    
    // Verify loading message is gone
    await expect(loadingMessage).not.toBeVisible();
  });
});
