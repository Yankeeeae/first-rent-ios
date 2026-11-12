import { chromium } from "playwright";
import { mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const out = join(dirname(fileURLToPath(import.meta.url)), "fr-FR");
await mkdir(out, { recursive: true });
const browser = await chromium.launch();
const page = await browser.newPage({
  viewport: { width: 430, height: 932 },
  deviceScaleFactor: 3,
  isMobile: true,
  hasTouch: true
});
await page.goto("https://first-rent.vercel.app/?app=1", { waitUntil: "networkidle" });
await page.waitForTimeout(1800);
await page.screenshot({ path: join(out, "01_accueil.png") });
await page.locator("#abord").scrollIntoViewIfNeeded();
await page.waitForTimeout(600);
await page.screenshot({ path: join(out, "02_vehicules.png") });
await page.locator("#agence").scrollIntoViewIfNeeded();
await page.waitForTimeout(600);
await page.screenshot({ path: join(out, "03_agence.png") });
await browser.close();
