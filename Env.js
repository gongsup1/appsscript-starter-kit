/**
 * DEV / PROD environments (GONG).
 * ONE code base, TWO twin Apps Script projects, each with its own Google Sheet and ONE deployment:
 *   "<APP NAME> (DEV)"  : where the developer tests, as often as they like;
 *   "<APP NAME> (PROD)" : what users run; only receives code already validated in DEV.
 * The running environment is identified by the PROJECT ID (ScriptApp.getScriptId(), reliable),
 * never by the URL nor by a URL parameter. See AGENTS.md rules 2 and 11.
 *
 * DEV and PROD behave differently, by construction:
 *   - notifications: in DEV every e-mail is redirected to the developer (notify_, AGENTS.md §8.a);
 *   - test and "view as" features: DEV only, refused SERVER-SIDE in PROD (requireDev_);
 *   - a DEV banner is shown (Index.html) so nobody mistakes one for the other.
 */

/* ============ CONFIG (filled at setup, AGENTS.md §3) ============ */
// Script IDs and Sheets are not secrets: they live in Git. A Sheet can be a full URL or a bare ID.
const ENVIRONMENTS = {
  DEV:  { scriptId: '<SCRIPT_ID_DEV>',  sheet: '<URL_OU_ID_SHEET_DEV>' },
  PROD: { scriptId: '<SCRIPT_ID_PROD>', sheet: '<URL_OU_ID_SHEET_PROD>' },
};

// THE environment of this project: 'DEV' or 'PROD' ('INCONNU' if the project is neither).
// Computed from the project ID, never typed by hand: the code is identical in both projects, and
// a copied project gets a new ID, so it can never inherit the wrong environment.
// Use ENV inside functions only (another file's top-level code may run before this one).
const ENV = (function () {
  const id = ScriptApp.getScriptId();
  if (id === ENVIRONMENTS.PROD.scriptId) return 'PROD';
  if (id === ENVIRONMENTS.DEV.scriptId) return 'DEV';
  return 'INCONNU';
})();

// ENV, or an error if the project is unknown: it must never run as PROD by accident, nor as DEV
// on real data. Every environment-dependent helper goes through here.
function checkEnv_() {
  if (ENV === 'INCONNU') {
    throw new Error('Environnement inconnu (projet ' + ScriptApp.getScriptId() + ') : renseigner ENVIRONMENTS dans Env.js.');
  }
  return ENV;
}

function isDev_() {
  return checkEnv_() === 'DEV';
}

// Google Sheet of the CURRENT environment: DEV data never mixes with PROD data.
function envSheetSource_() {
  return ENVIRONMENTS[checkEnv_()].sheet;
}

// Open the Google Sheet of the CURRENT environment. EVERY Sheet access goes through here (by id,
// NEVER getActiveSpreadsheet(): unreliable in /exec and triggers, and blind to DEV/PROD).
function envSpreadsheet_() {
  return SpreadsheetApp.openById(sheetId_(envSheetSource_()));
}

// Accept a full Sheet URL or a bare ID: extract the ID from a URL, else return it as-is.
// A Sheet URL looks like: https://docs.google.com/spreadsheets/d/THE_ID/edit
function sheetId_(source) {
  const m = String(source).match(/\/d\/([A-Za-z0-9_-]+)/);
  return m ? m[1] : String(source).trim();
}

// Email of the signed-in Workspace user (same domain). Empty string if unavailable.
function currentUser_() {
  try {
    return Session.getActiveUser().getEmail() || '';
  } catch (e) {
    return '';
  }
}

// Call it FIRST in every test / debug / "view as" server function. Hiding a button is not
// enough: any public server function can be called from the browser console.
function requireDev_() {
  if (!isDev_()) throw new Error("Fonction réservée à l'environnement DEV.");
}

// The developer: the account the DEV project runs as (web app deployer, trigger owner, or the
// person running a function in the editor). DEV notifications are redirected to this address.
function developerEmail_() {
  return Session.getEffectiveUser().getEmail();
}

// The user as the app should see them. In DEV only, "view as" lets the developer see the app as
// someone else (e-mail typed in the DEV banner). In PROD it is ALWAYS the real signed-in user:
// viewAs is ignored, whatever the browser sends.
function appUser_(viewAs) {
  const asked = String(viewAs || '').trim().toLowerCase();
  if (asked && isDev_() && /^[^@\s]+@[^@\s]+$/.test(asked)) return asked;
  return currentUser_();
}
