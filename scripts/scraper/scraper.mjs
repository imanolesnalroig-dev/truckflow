/**
 * Timocom Lithuanian Company Scraper
 *
 * Usage:
 *   TIMOCOM_USER=email TIMOCOM_PASS=password node scraper.mjs
 *
 * Options (env vars):
 *   HEADLESS=false    - Run with visible browser (useful for debugging)
 *   MAX_COMPANIES=0   - Limit companies to scrape (0 = all)
 *   OUTPUT=output.xlsx - Output file name
 */

import { chromium } from "playwright";
import ExcelJS from "exceljs";
import { writeFileSync, existsSync, readFileSync } from "fs";

// ── Config ──────────────────────────────────────────────────────────────
const EMAIL = process.env.TIMOCOM_USER;
const PASSWORD = process.env.TIMOCOM_PASS;
const HEADLESS = process.env.HEADLESS !== "false";
const MAX_COMPANIES = parseInt(process.env.MAX_COMPANIES || "0", 10);
const OUTPUT = process.env.OUTPUT || "timocom_lithuania.xlsx";
const CHECKPOINT_FILE = "checkpoint.json";
const BASE_URL = "https://my.timocom.com/app/tcgate/";

if (!EMAIL || !PASSWORD) {
  console.error(
    "❌ Set TIMOCOM_USER and TIMOCOM_PASS environment variables.\n" +
      "   Example: TIMOCOM_USER=user@example.com TIMOCOM_PASS=mypass node scraper.mjs"
  );
  process.exit(1);
}

// ── Helpers ─────────────────────────────────────────────────────────────
function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function randomDelay(min = 800, max = 2000) {
  return sleep(min + Math.random() * (max - min));
}

function loadCheckpoint() {
  if (existsSync(CHECKPOINT_FILE)) {
    return JSON.parse(readFileSync(CHECKPOINT_FILE, "utf-8"));
  }
  return { scraped: [], lastIndex: 0 };
}

function saveCheckpoint(data) {
  writeFileSync(CHECKPOINT_FILE, JSON.stringify(data, null, 2));
}

// ── Main ────────────────────────────────────────────────────────────────
async function main() {
  const checkpoint = loadCheckpoint();
  const allCompanies = checkpoint.scraped || [];
  const scrapedNames = new Set(allCompanies.map((c) => c.companyName));

  console.log(
    `📋 Checkpoint: ${allCompanies.length} companies already scraped`
  );

  const browser = await chromium.launch({
    headless: HEADLESS,
    slowMo: HEADLESS ? 0 : 50,
  });

  const context = await browser.newContext({
    viewport: { width: 1440, height: 900 },
    userAgent:
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
  });

  const page = await context.newPage();
  page.setDefaultTimeout(30000);

  try {
    // ── Step 1: Login ─────────────────────────────────────────────────
    console.log("🔐 Logging in...");
    await page.goto(BASE_URL, { waitUntil: "networkidle" });
    await sleep(2000);

    // Take a screenshot to understand the page structure
    await page.screenshot({ path: "debug_01_initial.png", fullPage: true });

    // Handle cookie consent if present
    try {
      const cookieBtn = page.locator(
        'button:has-text("Accept"), button:has-text("Akzeptieren"), button:has-text("agree"), [data-testid="cookie-accept"]'
      );
      if (await cookieBtn.first().isVisible({ timeout: 3000 })) {
        await cookieBtn.first().click();
        await sleep(1000);
      }
    } catch {
      // No cookie banner
    }

    // Try to find login form - Timocom may use various login flows
    // First check if we're already on a login page or need to navigate
    const currentUrl = page.url();
    console.log(`  Current URL: ${currentUrl}`);

    // Look for email/username input
    const emailSelectors = [
      'input[type="email"]',
      'input[name="email"]',
      'input[name="username"]',
      'input[name="login"]',
      'input[id*="email"]',
      'input[id*="user"]',
      'input[placeholder*="mail"]',
      'input[placeholder*="user"]',
      'input[placeholder*="Email"]',
      'input[placeholder*="User"]',
    ];

    let emailInput = null;
    for (const sel of emailSelectors) {
      try {
        const el = page.locator(sel).first();
        if (await el.isVisible({ timeout: 2000 })) {
          emailInput = el;
          console.log(`  Found email input: ${sel}`);
          break;
        }
      } catch {
        // Try next
      }
    }

    if (!emailInput) {
      // Maybe there's a "Login" button we need to click first
      try {
        const loginLink = page.locator(
          'a:has-text("Login"), a:has-text("Sign in"), button:has-text("Login"), button:has-text("Sign in")'
        );
        if (await loginLink.first().isVisible({ timeout: 3000 })) {
          await loginLink.first().click();
          await sleep(3000);
        }
      } catch {
        // Continue
      }

      // Try again
      for (const sel of emailSelectors) {
        try {
          const el = page.locator(sel).first();
          if (await el.isVisible({ timeout: 2000 })) {
            emailInput = el;
            console.log(`  Found email input after nav: ${sel}`);
            break;
          }
        } catch {
          // Try next
        }
      }
    }

    if (!emailInput) {
      await page.screenshot({ path: "debug_02_no_login.png", fullPage: true });
      console.error(
        "❌ Could not find login form. Check debug_02_no_login.png"
      );
      // Dump page content for debugging
      const html = await page.content();
      writeFileSync("debug_page.html", html);
      console.log("  Page HTML saved to debug_page.html");
      await browser.close();
      process.exit(1);
    }

    // Fill login
    await emailInput.fill(EMAIL);
    await randomDelay(500, 1000);

    // Find password input
    const passInput = page.locator('input[type="password"]').first();
    await passInput.fill(PASSWORD);
    await randomDelay(500, 1000);

    await page.screenshot({ path: "debug_03_filled_login.png", fullPage: true });

    // Submit login
    const submitSelectors = [
      'button[type="submit"]',
      'button:has-text("Login")',
      'button:has-text("Sign in")',
      'button:has-text("Log in")',
      'button:has-text("Anmelden")',
      'input[type="submit"]',
    ];

    for (const sel of submitSelectors) {
      try {
        const btn = page.locator(sel).first();
        if (await btn.isVisible({ timeout: 1000 })) {
          await btn.click();
          console.log(`  Clicked submit: ${sel}`);
          break;
        }
      } catch {
        // Try next
      }
    }

    // Wait for login to complete
    await sleep(5000);
    await page.screenshot({ path: "debug_04_after_login.png", fullPage: true });
    console.log(`  URL after login: ${page.url()}`);

    // ── Step 2: Navigate to Company Search ────────────────────────────
    console.log("🔍 Navigating to Company Search...");

    // Try clicking "Company search" in the menu/nav
    const companySearchSelectors = [
      'text="Company search"',
      'text="Company Search"',
      'text="Firmensuche"',
      'a:has-text("Company")',
      '[data-testid*="company"]',
      'text="Unternehmenssuche"',
    ];

    let foundCompanySearch = false;
    for (const sel of companySearchSelectors) {
      try {
        const el = page.locator(sel).first();
        if (await el.isVisible({ timeout: 3000 })) {
          await el.click();
          foundCompanySearch = true;
          console.log(`  Clicked: ${sel}`);
          break;
        }
      } catch {
        // Try next
      }
    }

    if (!foundCompanySearch) {
      // Try navigating directly
      const searchUrls = [
        "https://my.timocom.com/app/tcgate/company-search",
        "https://my.timocom.com/app/tcgate/#/company-search",
        "https://my.timocom.com/app/tcgate/companies",
      ];
      for (const url of searchUrls) {
        try {
          await page.goto(url, { waitUntil: "networkidle", timeout: 10000 });
          console.log(`  Navigated to: ${url}`);
          foundCompanySearch = true;
          break;
        } catch {
          // Try next
        }
      }
    }

    await sleep(3000);
    await page.screenshot({
      path: "debug_05_company_search.png",
      fullPage: true,
    });

    // ── Step 3: Search for Lithuania ───────────────────────────────────
    console.log("🇱🇹 Searching for Lithuanian companies...");

    // Look for location/country input
    const locationSelectors = [
      'input[placeholder*="location"]',
      'input[placeholder*="Location"]',
      'input[placeholder*="country"]',
      'input[placeholder*="Country"]',
      'input[placeholder*="Standort"]',
      'input[placeholder*="Land"]',
      'input[aria-label*="location"]',
      'input[aria-label*="Location"]',
      'input[aria-label*="country"]',
      'input[name*="location"]',
      'input[name*="country"]',
    ];

    let locationInput = null;
    for (const sel of locationSelectors) {
      try {
        const el = page.locator(sel).first();
        if (await el.isVisible({ timeout: 2000 })) {
          locationInput = el;
          console.log(`  Found location input: ${sel}`);
          break;
        }
      } catch {
        // Try next
      }
    }

    if (!locationInput) {
      // Try clicking a "Location" label or filter first
      try {
        const filterBtn = page.locator(
          'text="Location", text="Country", text="Company location", text="Firmenstandort"'
        );
        if (await filterBtn.first().isVisible({ timeout: 3000 })) {
          await filterBtn.first().click();
          await sleep(1000);
        }
      } catch {
        // Continue
      }

      // Try finding any visible input
      const allInputs = page.locator(
        'input[type="text"], input[type="search"], input:not([type])'
      );
      const count = await allInputs.count();
      console.log(`  Found ${count} text inputs on page`);
      for (let i = 0; i < count; i++) {
        const inp = allInputs.nth(i);
        if (await inp.isVisible()) {
          const placeholder = await inp.getAttribute("placeholder");
          const label = await inp.getAttribute("aria-label");
          const name = await inp.getAttribute("name");
          console.log(
            `  Input ${i}: placeholder="${placeholder}" aria-label="${label}" name="${name}"`
          );
        }
      }
    }

    if (locationInput) {
      await locationInput.click();
      await sleep(500);
      await locationInput.fill("Lithuania");
      await sleep(2000);

      // Select from autocomplete dropdown
      try {
        const option = page.locator(
          'li:has-text("Lithuania"), [role="option"]:has-text("Lithuania"), div[class*="option"]:has-text("Lithuania"), div[class*="suggestion"]:has-text("Lithuania")'
        );
        if (await option.first().isVisible({ timeout: 3000 })) {
          await option.first().click();
          await sleep(1000);
        }
      } catch {
        // Try pressing Enter
        await locationInput.press("Enter");
      }
    } else {
      console.log(
        "⚠️  Could not find location input. Trying to type Lithuania in first visible input..."
      );
      // Last resort: dump page for debugging
      await page.screenshot({
        path: "debug_06_no_location.png",
        fullPage: true,
      });
      const html = await page.content();
      writeFileSync("debug_page_search.html", html);
    }

    // Click search button
    const searchBtnSelectors = [
      'button:has-text("Search")',
      'button:has-text("Suchen")',
      'button[type="submit"]',
      'button:has-text("Find")',
      '[data-testid*="search"]',
    ];

    for (const sel of searchBtnSelectors) {
      try {
        const btn = page.locator(sel).first();
        if (await btn.isVisible({ timeout: 2000 })) {
          await btn.click();
          console.log(`  Clicked search: ${sel}`);
          break;
        }
      } catch {
        // Try next
      }
    }

    await sleep(5000);
    await page.screenshot({ path: "debug_07_results.png", fullPage: true });

    // ── Step 4: Scrape company list ───────────────────────────────────
    console.log("📊 Scraping company list...");

    let pageNum = 1;
    let hasMore = true;

    while (hasMore) {
      console.log(`  Page ${pageNum}...`);

      // Find company entries in the list
      // Common patterns for list items
      const companyCardSelectors = [
        '[class*="company-card"]',
        '[class*="CompanyCard"]',
        '[class*="search-result"]',
        '[class*="SearchResult"]',
        '[class*="result-item"]',
        '[class*="ResultItem"]',
        'tr[class*="row"]',
        '[data-testid*="company"]',
        '[class*="list-item"]',
        ".company-item",
        "[class*='company'] [class*='item']",
      ];

      let companyCards = null;
      for (const sel of companyCardSelectors) {
        try {
          const cards = page.locator(sel);
          const count = await cards.count();
          if (count > 0) {
            companyCards = cards;
            console.log(`  Found ${count} companies with selector: ${sel}`);
            break;
          }
        } catch {
          // Try next
        }
      }

      if (!companyCards) {
        // Try a more generic approach - look for clickable rows/items
        // that look like company listings
        console.log("  Trying generic approach to find company entries...");

        // Get all links/clickable elements that might be company names
        const links = page.locator("a, [role='link'], [role='row']");
        const linkCount = await links.count();
        console.log(`  Found ${linkCount} clickable elements`);

        // Dump first few for inspection
        for (let i = 0; i < Math.min(10, linkCount); i++) {
          const text = await links.nth(i).textContent();
          const href = await links.nth(i).getAttribute("href");
          if (text && text.trim().length > 3) {
            console.log(
              `    Link ${i}: "${text.trim().substring(0, 80)}" href=${href}`
            );
          }
        }

        await page.screenshot({ path: "debug_08_no_cards.png", fullPage: true });

        // Save page HTML for manual inspection
        const html = await page.content();
        writeFileSync("debug_results_page.html", html);
        console.log("  Saved page HTML to debug_results_page.html");
        console.log(
          "  ⚠️ Could not identify company cards. Please run with HEADLESS=false to debug."
        );
        break;
      }

      const cardCount = await companyCards.count();
      const limit =
        MAX_COMPANIES > 0
          ? Math.min(cardCount, MAX_COMPANIES - allCompanies.length)
          : cardCount;

      for (let i = 0; i < limit; i++) {
        try {
          const card = companyCards.nth(i);
          const companyName = (await card.textContent())?.trim() || "";

          // Skip already scraped
          if (scrapedNames.has(companyName)) {
            console.log(`  ⏭️ Already scraped: ${companyName.substring(0, 50)}`);
            continue;
          }

          console.log(
            `  📄 [${allCompanies.length + 1}] ${companyName.substring(0, 60)}...`
          );

          // Click to open company detail
          await card.click();
          await sleep(3000);

          // Extract company details
          const details = await extractCompanyDetails(page);
          details.companyName =
            details.companyName || companyName.split("\n")[0]?.trim() || "";

          allCompanies.push(details);
          scrapedNames.add(details.companyName);

          // Save checkpoint every 5 companies
          if (allCompanies.length % 5 === 0) {
            saveCheckpoint({ scraped: allCompanies, lastIndex: i });
            console.log(`  💾 Checkpoint saved (${allCompanies.length} total)`);
          }

          // Go back to results
          await page.goBack();
          await sleep(2000);

          // Random delay to avoid rate limiting
          await randomDelay(1500, 3500);

          if (
            MAX_COMPANIES > 0 &&
            allCompanies.length >= MAX_COMPANIES
          ) {
            console.log(`  ✅ Reached max companies limit: ${MAX_COMPANIES}`);
            hasMore = false;
            break;
          }
        } catch (err) {
          console.log(`  ⚠️ Error on company ${i}: ${err.message}`);
          // Try to recover by going back
          try {
            await page.goBack();
            await sleep(2000);
          } catch {
            // Reload results page
            await page.reload();
            await sleep(5000);
          }
        }
      }

      if (!hasMore) break;

      // Try to go to next page
      try {
        const nextBtn = page.locator(
          'button:has-text("Next"), a:has-text("Next"), button:has-text("Weiter"), [aria-label="Next page"], button:has-text("›"), button:has-text("»"), [class*="next"]'
        );
        if (await nextBtn.first().isVisible({ timeout: 3000 })) {
          await nextBtn.first().click();
          await sleep(3000);
          pageNum++;
        } else {
          console.log("  No more pages.");
          hasMore = false;
        }
      } catch {
        console.log("  No pagination found, assuming single page.");
        hasMore = false;
      }
    }

    // ── Step 5: Export to Excel ──────────────────────────────────────
    console.log(`\n📊 Exporting ${allCompanies.length} companies to ${OUTPUT}...`);
    await exportToExcel(allCompanies, OUTPUT);

    // Final checkpoint
    saveCheckpoint({ scraped: allCompanies, lastIndex: 0 });

    console.log(`✅ Done! ${allCompanies.length} companies saved to ${OUTPUT}`);
  } catch (err) {
    console.error("❌ Fatal error:", err);
    await page.screenshot({ path: "debug_error.png", fullPage: true });
  } finally {
    await browser.close();
  }
}

// ── Extract company details from detail page ────────────────────────────
async function extractCompanyDetails(page) {
  const details = {
    companyName: "",
    address: "",
    country: "",
    phone: "",
    fax: "",
    email: "",
    website: "",
    vatId: "",
    timocomId: "",
    services: "",
    contacts: [],
  };

  try {
    await page.screenshot({
      path: `debug_detail_${Date.now()}.png`,
      fullPage: true,
    });

    // Company name - usually in a heading
    try {
      const heading = page.locator("h1, h2, [class*='company-name'], [class*='CompanyName']").first();
      if (await heading.isVisible({ timeout: 2000 })) {
        details.companyName = (await heading.textContent())?.trim() || "";
      }
    } catch { /* ignore */ }

    // Extract all text content and parse
    const pageText = await page.textContent("body");

    // Try to find email addresses via regex
    const emailRegex = /[\w.+-]+@[\w-]+\.[\w.-]+/g;
    const emails = pageText.match(emailRegex) || [];
    details.email = [...new Set(emails)].join("; ");

    // Phone numbers
    const phoneRegex = /(?:\+\d{1,3}[-.\s]?)?\(?\d{1,4}\)?[-.\s]?\d{1,4}[-.\s]?\d{1,9}/g;
    const phones = pageText.match(phoneRegex) || [];

    // Try specific selectors for structured data
    const fieldSelectors = {
      phone: [
        '[class*="phone"]',
        '[data-testid*="phone"]',
        'a[href^="tel:"]',
      ],
      email: [
        '[class*="email"]',
        '[data-testid*="email"]',
        'a[href^="mailto:"]',
      ],
      website: [
        '[class*="website"]',
        '[class*="web"]',
        'a[href^="http"]:not([href*="timocom"])',
      ],
      address: ['[class*="address"]', '[class*="Address"]'],
    };

    for (const [field, selectors] of Object.entries(fieldSelectors)) {
      for (const sel of selectors) {
        try {
          const el = page.locator(sel).first();
          if (await el.isVisible({ timeout: 1000 })) {
            const text = (await el.textContent())?.trim();
            const href = await el.getAttribute("href");
            if (field === "email" && href?.startsWith("mailto:")) {
              details.email = href.replace("mailto:", "") + (details.email ? "; " + details.email : "");
            } else if (field === "phone" && href?.startsWith("tel:")) {
              details.phone = href.replace("tel:", "");
            } else if (text) {
              details[field] = details[field] || text;
            }
            break;
          }
        } catch { /* ignore */ }
      }
    }

    // Look for contacts section
    try {
      const contactElements = page.locator(
        '[class*="contact"], [class*="Contact"], [class*="person"], [class*="Person"]'
      );
      const contactCount = await contactElements.count();

      for (let i = 0; i < contactCount; i++) {
        const contactEl = contactElements.nth(i);
        const contactText = (await contactEl.textContent())?.trim() || "";
        if (contactText.length > 3) {
          const contactEmails = contactText.match(emailRegex) || [];
          details.contacts.push({
            text: contactText.substring(0, 200),
            emails: contactEmails,
          });
        }
      }
    } catch { /* ignore */ }

    // Deduplicate emails
    const allEmails = new Set();
    if (details.email) details.email.split(";").map((e) => e.trim()).filter(Boolean).forEach((e) => allEmails.add(e));
    details.contacts.forEach((c) => c.emails.forEach((e) => allEmails.add(e)));
    details.email = [...allEmails].join("; ");
  } catch (err) {
    console.log(`    ⚠️ Error extracting details: ${err.message}`);
  }

  return details;
}

// ── Export to Excel ─────────────────────────────────────────────────────
async function exportToExcel(companies, filename) {
  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet("Lithuanian Companies");

  // Header style
  const headerStyle = {
    font: { bold: true, color: { argb: "FFFFFFFF" }, size: 11 },
    fill: {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: "FF2E5090" },
    },
    alignment: { horizontal: "center" },
    border: {
      bottom: { style: "thin" },
    },
  };

  // Define columns
  sheet.columns = [
    { header: "Company Name", key: "companyName", width: 40 },
    { header: "Address", key: "address", width: 40 },
    { header: "Country", key: "country", width: 15 },
    { header: "Phone", key: "phone", width: 25 },
    { header: "Fax", key: "fax", width: 25 },
    { header: "Email(s)", key: "email", width: 45 },
    { header: "Website", key: "website", width: 35 },
    { header: "VAT ID", key: "vatId", width: 20 },
    { header: "Timocom ID", key: "timocomId", width: 20 },
    { header: "Services", key: "services", width: 30 },
    { header: "Contacts", key: "contacts", width: 60 },
  ];

  // Apply header style
  sheet.getRow(1).eachCell((cell) => {
    Object.assign(cell, headerStyle);
  });

  // Add data
  for (const company of companies) {
    sheet.addRow({
      companyName: company.companyName || "",
      address: company.address || "",
      country: company.country || "Lithuania",
      phone: company.phone || "",
      fax: company.fax || "",
      email: company.email || "",
      website: company.website || "",
      vatId: company.vatId || "",
      timocomId: company.timocomId || "",
      services: company.services || "",
      contacts: (company.contacts || []).map((c) => c.text).join("\n---\n"),
    });
  }

  // Auto-filter
  sheet.autoFilter = {
    from: "A1",
    to: `K${companies.length + 1}`,
  };

  // Freeze header row
  sheet.views = [{ state: "frozen", ySplit: 1 }];

  await workbook.xlsx.writeFile(filename);
}

// ── Run ─────────────────────────────────────────────────────────────────
main().catch((err) => {
  console.error("Fatal:", err);
  process.exit(1);
});
