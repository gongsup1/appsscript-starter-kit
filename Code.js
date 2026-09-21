/**
 * <APP NAME> (GONG)
 * Google Apps Script backend. Serves the single-page web app (doGet) and reads/writes the
 * Google Sheet used as the single source of truth. Data tabs are created on demand.
 *
 * Hard rules baked in:
 *   1. Secrets live in Script Properties, NEVER in this file.
 *   2. Talk to the Sheet in BATCHES, not cell by cell (see PERFORMANCE HELPERS, AGENTS.md §6).
 *   3. The UI follows the shared design charter (design-system/): styles come from Styles.html
 *      and the header from Header.html, injected into Index.html via include().
 */

/* ============ CONFIG ============ */
// The data spreadsheet, as a FULL URL or a bare ID -- both work (sheetId_ extracts the ID).
// We ALWAYS open by id, NEVER getActiveSpreadsheet() (unreliable in /exec and triggers).
// A Sheet URL looks like: https://docs.google.com/spreadsheets/d/THE_ID/edit
const SHEET_SOURCE = '<URL_OU_ID_DU_GOOGLE_SHEET>';

// App name shown in the header + browser tab, and version shown in the footer. Injected by
// doGet(). Bump APP_VERSION on every publish so it matches the clasp version (AGENTS.md §4).
const APP_NAME = '<APP NAME>';
const APP_VERSION = 'v1';

// Data tabs and their header row. getTab_() creates any missing tab with these headers.
const TABS = {
  ENTRIES: { name: 'DONNEES', headers: ['Horodatage', 'Utilisateur', 'Message'] },
};

/* ============ WEB APP ENTRY POINT ============ */
function doGet() {
  // Serve Index.html as a template so the app name, version and signed-in user are injected
  // server-side, and so include('Styles')/include('Header') can drop in the design charter.
  const tpl = HtmlService.createTemplateFromFile('Index');
  tpl.appName = APP_NAME;
  tpl.appVersion = APP_VERSION;
  tpl.userEmail = currentUser_();
  tpl.userName = displayName_(tpl.userEmail);
  return tpl.evaluate()
    .setTitle(APP_NAME)
    .addMetaTag('viewport', 'width=device-width, initial-scale=1');
}

// Drop a project file's raw content into a template: <?!= include('Styles') ?>.
// Used to include the shared design charter (Styles.html, Header.html) in Index.html.
function include(name) {
  return HtmlService.createHtmlOutputFromFile(name).getContent();
}

// Email of the signed-in Workspace user (same domain). Empty string if unavailable.
function currentUser_() {
  try {
    return Session.getActiveUser().getEmail() || '';
  } catch (e) {
    return '';
  }
}

// Friendly display name from an email: "john.doe@gong-galaxy.com" -> "John Doe".
function displayName_(email) {
  if (!email) return '';
  var local = String(email).split('@')[0].replace(/[._-]+/g, ' ').trim();
  return local.replace(/\b\w/g, function (c) { return c.toUpperCase(); });
}

/* ============ READ / WRITE (called from the front-end via google.script.run) ============ */
// IMPORTANT: google.script.run serialises arrays/objects poorly (they can arrive as null in
// the browser). Always return a JSON STRING here and JSON.parse() it client-side (AGENTS.md, rule 7).
function getState() {
  const rows = readRows_('ENTRIES');
  const last = rows.length ? rows[rows.length - 1] : null;
  return JSON.stringify({
    count: rows.length,
    last: last ? { at: last[0], user: last[1], message: last[2] } : null
  });
}

// Append one test row (timestamp + current user). LockService serialises concurrent writers
// (several tablets at once) so two submissions never collide on the same row.
function addTestEntry() {
  const lock = LockService.getScriptLock();
  lock.waitLock(10000);
  try {
    getTab_('ENTRIES').appendRow([new Date(), currentUser_(), 'Entrée de test']);
  } finally {
    lock.releaseLock();
  }
  return getState();
}

/* ============ PERFORMANCE HELPERS ============ */
// Open the spreadsheet ONCE per execution and reuse the reference (openById is costly).
let _ss = null;
function ss_() {
  if (!_ss) _ss = SpreadsheetApp.openById(sheetId_(SHEET_SOURCE));
  return _ss;
}

// Accept a full Sheet URL or a bare ID: extract the ID from a URL, else return it as-is.
function sheetId_(source) {
  const m = String(source).match(/\/d\/([A-Za-z0-9_-]+)/);
  return m ? m[1] : String(source).trim();
}

// Read a whole tab in ONE call (getDataRange().getValues() is a single round-trip). Reading
// cell by cell in a loop is 10-100x slower. Returns data rows only (header dropped).
function readRows_(key) {
  const values = getTab_(key).getDataRange().getValues();
  values.shift(); // drop the header row
  return values;
}

// Cache rarely-changing data (config, people lists) so hot paths avoid the Sheet entirely.
// Example: return cachedJson_('operators', 300, function () { return readRows_('OPERATORS'); });
function cachedJson_(cacheKey, ttlSeconds, producer) {
  const cache = CacheService.getScriptCache();
  const hit = cache.get(cacheKey);
  if (hit) return JSON.parse(hit);
  const data = producer();
  cache.put(cacheKey, JSON.stringify(data), ttlSeconds);
  return data;
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
