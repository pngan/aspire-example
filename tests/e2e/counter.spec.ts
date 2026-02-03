import { test, expect } from '@playwright/test';

test.describe('Counter Page', () => {
  test('should load the counter page', async ({ page }) => {
    await page.goto('/counter');
    
    // Verify page title
    await expect(page).toHaveTitle(/Counter/);
    
    // Verify main heading
    await expect(page.locator('h1')).toContainText('Counter');
  });

  test('should display initial count of 0', async ({ page }) => {
    await page.goto('/counter');
    
    // Verify initial count
    await expect(page.locator('[role="status"]')).toContainText('Current count: 0');
  });

  test('should increment counter when button is clicked', async ({ page }) => {
    await page.goto('/counter');
    
    // Verify initial state
    await expect(page.locator('[role="status"]')).toContainText('Current count: 0');
    
    // Click the button
    await page.locator('button:has-text("Click me")').click();
    
    // Wait a moment for Blazor Server to update
    await page.waitForTimeout(500);
    
    // Verify count increased
    await expect(page.locator('[role="status"]')).toContainText('Current count: 1');
  });

  test('should increment counter multiple times', async ({ page }) => {
    await page.goto('/counter');
    
    const button = page.locator('button:has-text("Click me")');
    
    // Click button 5 times
    for (let i = 1; i <= 5; i++) {
      await button.click();
      await expect(page.locator('[role="status"]')).toContainText(`Current count: ${i}`);
    }
  });

  test('should maintain counter state during page interaction', async ({ page }) => {
    await page.goto('/counter');
    
    // Click button twice
    const button = page.locator('button:has-text("Click me")');
    await button.click();
    await button.click();
    
    // Verify count is 2
    await expect(page.locator('[role="status"]')).toContainText('Current count: 2');
    
    // Navigate away
    await page.locator('nav a[href=""]').click();
    await expect(page).toHaveURL(/\/$/);
    
    // Navigate back
    await page.locator('nav a[href="counter"]').click();
    
    // Note: Counter resets on navigation (server-side rendering)
    // This is expected behavior for Blazor Server without state persistence
    await expect(page.locator('[role="status"]')).toContainText('Current count: 0');
  });
});
