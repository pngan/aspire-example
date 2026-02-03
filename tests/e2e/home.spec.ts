import { test, expect } from '@playwright/test';

test.describe('Home Page', () => {
  test('should load the home page successfully', async ({ page }) => {
    await page.goto('/');
    
    // Verify page title
    await expect(page).toHaveTitle(/Home/);
    
    // Verify main heading
    await expect(page.locator('h1')).toContainText('Hello, world!');
    
    // Verify welcome message
    await expect(page.locator('text=Welcome to your new app')).toBeVisible();
  });

  test('should display navigation menu', async ({ page }) => {
    await page.goto('/');
    
    // Verify navigation links are present
    await expect(page.locator('nav a[href=""]')).toContainText('Home');
    await expect(page.locator('nav a[href="counter"]')).toContainText('Counter');
    await expect(page.locator('nav a[href="weather"]')).toContainText('Weather');
  });

  test('should display app branding', async ({ page }) => {
    await page.goto('/');
    
    // Verify navbar brand
    await expect(page.locator('.navbar-brand')).toContainText('AspireApp');
  });

  test('should navigate to counter page', async ({ page }) => {
    await page.goto('/');
    
    // Click counter link
    await page.locator('nav a[href="counter"]').click();
    
    // Verify navigation
    await expect(page).toHaveURL(/\/counter/);
    await expect(page.locator('h1')).toContainText('Counter');
  });

  test('should navigate to weather page', async ({ page }) => {
    await page.goto('/');
    
    // Click weather link
    await page.locator('nav a[href="weather"]').click();
    
    // Verify navigation
    await expect(page).toHaveURL(/\/weather/);
    await expect(page.locator('h1')).toContainText('Weather');
  });
});
