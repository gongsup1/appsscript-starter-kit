/**
 * <APP NAME> — GONG
 * Google Apps Script backend. Serves the single-page web app (doGet) and reads/writes
 * the Google Sheet used as the single source of truth (data AND access lists). Data tabs
 * are created on demand with their header row, so editing the Sheet never needs a redeploy.
 *
 * Two hard rules baked in here:
 *   1. Secrets (API keys, passwords) live in Script Properties, NEVER in this file.
 *   2. Talk to the Sheet in BATCHES, not cell by cell — each round-trip is slow (see
 *      the PERFORMANCE HELPERS section and AGENTS.md §6).
 */

/* ============ CONFIG ============ */
// ID of the data spreadsheet. We ALWAYS open it by id and NEVER call getActiveSpreadsheet():
// the latter is unreliable in a web app (/exec) and in time-driven triggers (it can point
// at another, empty spreadsheet).
const SHEET_ID = '<ID_DU_GOOGLE_SHEET>';

// Deployed version shown in the page footer. ALWAYS visible in the UI so anyone can see
// which version is running. Bump it on every publish so it matches the clasp version number
// and the git commit (AGENTS.md §4). Injected into Index.html by doGet().
const APP_VERSION = 'v1';

// Data tabs and their header row. getTab_() creates any missing tab with these headers.
// Add or rename tabs here; the Sheet stays the single source of truth.
const TABS = {
  ENTRIES: { name: 'DONNEES', headers: ['Horodatage', 'Nom', 'Valeur'] },
};

/* ============ PERFORMANCE HELPERS ============ */
// Open the spreadsheet ONCE per execution and reuse the reference. Each openById() is a
// slow round-trip; memoising it avoids paying that cost again in every helper.
let _ss = null;
function ss_() {
  if (!_ss) _ss = SpreadsheetApp.openById(SHEET_ID);
  return _ss;
}

// Read a whole tab in ONE call. getDataRange().getValues() is a single round-trip; reading
// cell by cell (getRange().getValue() inside a loop) is 10–100x slower. Returns data rows
// only (header dropped).
function readRows_(key) {
  const values = getTab_(key).getDataRange().getValues();
  values.shift(); // drop the header row
  return values;
}

// Cache rarely-changing data (config, people lists) so hot paths avoid the Sheet entirely.
// On a cache miss it calls producer(), stores the result as JSON, and returns it.
// Example: return cachedJson_('operators', 300, function () { return readRows_('OPERATORS'); });
function cachedJson_(cacheKey, ttlSeconds, producer) {
  const cache = CacheService.getScriptCache();
  const hit = cache.get(cacheKey);
  if (hit) return JSON.parse(hit);
  const data = producer();
  cache.put(cacheKey, JSON.stringify(data), ttlSeconds);
  return data;
}

/* ============ WEB APP ENTRY POINT ============ */
function doGet() {
  // Serve the single-page front-end (Index.html) as a template so APP_VERSION can be
  // injected server-side — the footer then always shows the exact deployed version.
  const tpl = HtmlService.createTemplateFromFile('Index');
  tpl.appVersion = APP_VERSION;
  return tpl.evaluate()
    .setTitle('<APP NAME>')
    .addMetaTag('viewport', 'width=device-width, initial-scale=1');
}

/* ============ READ (called from the front-end via google.script.run) ============ */
// IMPORTANT: google.script.run serialises arrays of objects poorly (they can arrive as
// null in the browser). Always return a JSON STRING here and JSON.parse() it client-side.
function getData() {
  const rows = readRows_('ENTRIES').map(function (r) {
    return { timestamp: r[0], name: r[1], value: r[2] };
  });
  return JSON.stringify(rows);
}

/* ============ WRITE ============ */
// Append one entry. LockService serialises concurrent writers (several tablets at once),
// so two submissions never collide on the same row. Keep the critical section short.
function saveEntry(payload) {
  const lock = LockService.getScriptLock();
  lock.waitLock(10000); // wait up to 10s for other writers
  try {
    getTab_('ENTRIES').appendRow([new Date(), payload.name, payload.value]);
  } finally {
    lock.releaseLock();
  }
  return JSON.stringify({ ok: true });
}

/* ============ SHEET HELPERS ============ */
// Returns a tab by its logical key from TABS, creating it (with headers) if missing.
// Functions whose name ends with "_" are private: they never appear in the editor's Run menu.
function getTab_(key) {
  const conf = TABS[key];
  let sheet = ss_().getSheetByName(conf.name);
  if (!sheet) {
    sheet = ss_().insertSheet(conf.name);
    sheet.appendRow(conf.headers);
  }
  return sheet;
}
