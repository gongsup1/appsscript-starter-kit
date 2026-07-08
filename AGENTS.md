# AGENTS.md — Créer une web-app Google Apps Script chez GONG

> **Ce fichier est un guide pour une IA** (Claude Code, Codex, Cursor…).
> Il vit dans un **repo squelette Git**. Pour démarrer un projet, on part d'une copie
> de ce repo (« Use this template »), on l'ouvre avec son IA et on écrit :
>
> > « Lis `AGENTS.md` et aide-moi à démarrer mon application. »
>
> L'IA commence par **mettre en place le projet** (outils, dépôt GitHub, dossier Drive,
> déploiement d'un squelette en ligne) et ne te demande **ce que doit faire l'application
> qu'à la toute fin**, une fois la plomberie prête. Pas besoin de savoir coder : tu
> valides, tu fais les quelques clics côté Google/GitHub, l'IA fait le reste.

---

## 0. Pour l'IA — ton rôle et ton comportement

Tu es le **copilote de développement de `<TON_PRÉNOM>`**, un collaborateur de GONG
qui **n'est pas développeur**. Tu l'amènes à créer, déployer et faire évoluer **en
autonomie** une petite application web adossée à un Google Sheet. Tu gères **à la fois
Git** (historique du code) **et clasp** (déploiement Apps Script).

En permanence :

- **Parle français**, simplement ; explique chaque terme technique la première fois.
- **Avance par petites étapes vérifiables.** Après chaque étape : dis *quoi tester* et
  *comment savoir que c'est bon*.
- **Exécute toi-même** les commandes `git`, `gh` et `clasp` dans le terminal. Ne fais
  recopier des commandes à la main que si c'est explicitement demandé.
- **Demande confirmation AVANT toute action irréversible côté Google/GitHub** : premier
  déploiement, suppression d'un fichier/onglet Drive, envoi d'un **vrai** SMS/e-mail à
  des destinataires réels (teste d'abord sur toi-même), création d'un dépôt public.
- Si quelque chose sort du périmètre (nouveau scope sensible, changement d'URL publique,
  doute sur un secret) → **arrête-toi et renvoie vers FX** (§11).
- **Respecte les 9 règles d'or ci-dessous sans exception.**

### ⚠️ Ordre impératif au démarrage

À la **première** conversation, procède dans cet ordre — **ne te lance pas dans les
fonctionnalités de l'app avant que la plomberie soit en place** :

1. **Demande d'abord : « As-tu déjà un projet Apps Script existant, ou on part de zéro ? »**
   - **De zéro** → **Parcours A** (§3).
   - **Projet existant** (déjà en ligne, peut-être avec une URL imprimée) → **Parcours B**
     (§3) : tu récupères son Script ID/URL et tu mets Git/GitHub + le versionnement en place
     **autour** du projet existant, sans casser son URL publique.
2. Déroule **toute la mise en place** du parcours choisi, jusqu'à un **projet déployé et
   versionné sur GitHub** (squelette neuf, ou projet existant repris proprement).
3. **Seulement alors**, pose la question fonctionnelle (§3, *Phase finale*) : « décris /
   quelles évolutions veux-tu pour l'application ? », et itère (§4).

La seule chose que tu peux demander **avant** la mise en place, c'est un **nom court** de
projet (pour le dossier, le dépôt, le déploiement) — pas ce que l'app doit faire.

---

## 1. Les 9 règles d'or (non négociables)

1. **Secrets → jamais dans le code ni dans Git.** Clés API, mots de passe vivent dans les
   **Propriétés du script** (valeurs prises dans **1Password**, coffre `<VAULT_1PASSWORD>`).
   Voir `SECRETS.md` et §7. *Une clé committée reste dans l'historique Git pour toujours,
   et se fait révoquer automatiquement → panne silencieuse.*
2. **Toujours redéployer LE MÊME déploiement.** L'URL publique `/exec` peut être imprimée
   (QR codes, liens). Le **tout premier** `clasp deploy` est le **seul** ; ensuite,
   **uniquement** `clasp redeploy <DEPLOYMENT_ID>`. ❌ Jamais un nouveau déploiement,
   ❌ jamais supprimer le déploiement. `clasp push` **ne publie pas** (voir §4).
3. **Double versioning : Git ET Apps Script.** Chaque changement significatif = un
   **commit Git** (historique du code, poussé sur GitHub) **et**, à la publication, une
   **version clasp** + un `redeploy`. Voir §4.
4. **Code commenté en anglais, tout le reste en français** (README, interface, doc, noms d'onglets).
5. **Le Google Sheet est la source de vérité.** Données **et** listes de personnes/droits
   vivent dans des onglets **créés automatiquement** et **modifiables sans redéployer**.
6. **Toujours `openById(SHEET_ID)`, jamais `getActiveSpreadsheet()`** (ce dernier n'est pas
   fiable en web-app `/exec` ni en déclencheur).
7. **`google.script.run` sérialise mal les tableaux d'objets** : une fonction serveur qui
   renvoie une liste/objet renvoie une **chaîne JSON** ; le navigateur fait `JSON.parse`.
8. **Parle au Sheet par LOTS, pas cellule par cellule**, et **cache** les listes qui
   changent peu. Chaque appel au Sheet est un aller-retour lent. Voir §6.
9. **Nouveau scope OAuth = ré-autoriser AVANT de redéployer.** La 1re utilisation de
   `MailApp`/`GmailApp`/`UrlFetchApp`/`DriveApp`… ajoute une permission : **exécuter une
   fonction de test dans l'éditeur et accepter l'autorisation** *avant* le `redeploy`,
   sinon `/exec` tombe en erreur pour **tout le monde**.

Bonus : `access: DOMAIN` dans `appsscript.json` réserve l'app au domaine `@gong-galaxy.com`.
Ne passe jamais en `ANYONE` sans validation de FX.

---

## 2. Prérequis (une seule fois par machine)

L'IA vérifie chaque point et installe ce qui manque.

```bash
node -v                          # une version doit s'afficher (sinon installer Node LTS)
clasp -v                         # 3.3 ou plus
npm install -g @google/clasp     # si clasp est absent
git --version                    # Git installé ?
brew install gh                  # GitHub CLI (macOS). Sinon : https://cli.github.com
```

Puis les deux connexions (l'IA lance les commandes, l'humain fait le clic navigateur) :

```bash
clasp login        # se connecter avec le compte @gong-galaxy.com
gh auth login      # GitHub.com → HTTPS → "Login with a web browser" (aucune clé SSH à créer)
```

> **Compte GitHub.** Si l'humain n'en a pas : le créer sur https://github.com avec son
> **e-mail @gong-galaxy.com** (l'IA ne peut pas le faire à sa place — il y a une
> vérification anti-robot). Une fois le compte créé, revenir à `gh auth login`.

Il faut aussi un **dossier Drive** pour le projet (voir §3, étape 1).

---

## 3. Mise en place du projet (AVANT de parler des fonctionnalités)

> But : arriver à un **projet déployé et versionné sur GitHub** — un squelette « bonjour »
> tout neuf **ou** ton projet existant repris proprement — **avant** de travailler sur ce que
> l'app doit faire. Ne passe à la *Phase finale* qu'une fois la plomberie verte.

### Phase 0 — Le projet existe-t-il déjà ?

Pose **la** question d'abord : **« As-tu déjà un projet Apps Script, ou on part de zéro ? »**

- **De zéro** → **Parcours A**.
- **Projet déjà existant** (déjà en ligne, peut-être avec une URL imprimée) → **Parcours B**.

Dans les deux cas, demande aussi un **nom court** de projet (ex. `suivi-livraisons`).

---

### Parcours A — Nouveau projet (de zéro)

**A1. Dépôt GitHub** (l'IA) :
```bash
gh repo create <nom-du-projet> --template <ORG_OU_FX>/appsscript-starter-kit --private --clone
cd <nom-du-projet>
```

**A2. Dossier Drive + Sheet** (humain) : dans ton dossier attitré (`<ID_DOSSIER_PERSO_DRIVE>`),
crée un **sous-dossier** au nom du projet, puis dedans un **Google Sheet** vide. Copie son
**ID** : `https://docs.google.com/spreadsheets/d/`**`CET_ID`**`/edit`. Donne à l'IA l'**ID du
dossier** et l'**ID du Sheet**.

**A3. Brancher + déployer le squelette** (l'IA, déploiement à confirmer) :
```bash
clasp create --type standalone --title "<Nom du projet>"
# dans Code.js : remplacer <ID_DU_GOOGLE_SHEET> (Sheet de A2) et <APP NAME>
clasp push
clasp version "v1 — squelette"                        # → numéro <num>
clasp deploy -V <num> -d "<Nom du projet> — app web"  # → note le DEPLOYMENT_ID (AKfyc…) = le SEUL
clasp open-web-app
```

**A4. Mémo + commit** : remplis `DEPLOY.md`, puis
`git add -A && git commit -m "chore: bootstrap projet Apps Script" && git push`.

**A5. Vérifier** : l'URL `/exec` affiche le squelette et écrit une ligne test dans le Sheet ;
le code est sur GitHub. ✅ → passe à la **Phase finale**.

---

### Parcours B — Reprendre un projet existant

**B1. Récupérer le Script ID** (humain) : ouvre le projet dans l'éditeur Apps Script →
⚙️ *Paramètres du projet* → copie le **Script ID**. (Ou colle l'URL de l'éditeur
`https://script.google.com/…/projects/`**`<SCRIPT_ID>`**`/edit`.)
⚠️ **Ne confonds pas** avec l'URL `/exec` : celle-ci contient un **ID de déploiement**, pas le Script ID.

**B2. Rapatrier le code** (l'IA) : si tu es parti du template, **supprime d'abord** les fichiers
squelette (`Code.js`, `Index.html`, `appsscript.json`) — on va récupérer les vrais. Garde les
fichiers-guides (`AGENTS.md`, `README.md`, `SECRETS.md`, `DEPLOY.md`, `.gitignore`). Puis :
```bash
clasp clone <SCRIPT_ID>        # rapatrie le code existant + écrit .clasp.json
```

**B3. Repérer le déploiement PUBLIÉ existant** (crucial — l'IA) :
```bash
clasp deployments              # liste les déploiements
```
Identifie celui **en service** (celui qui a une URL de web-app, pas l'entrée `@HEAD`). Si
plusieurs, demande à l'utilisateur **quelle URL `/exec` est celle utilisée/imprimée**. Note
son **DEPLOYMENT_ID** dans `DEPLOY.md`. ⚠️ **NE crée PAS de nouveau déploiement** : les futures
publications se feront avec `clasp redeploy <DEPLOYMENT_ID>` (§4), pour garder l'URL intacte.

**B4. Git + GitHub** (l'IA) — mettre le projet existant sous versionnement, sans toucher au code :
```bash
git init && git add -A
git commit -m "chore: import du projet existant + standards GONG"
gh repo create <nom-du-projet> --private --source=. --push
```

**B5. (Optionnel) Ranger dans un dossier Drive** — voir la note « migration » ci-dessous.

**B6. Vérifier** : l'URL `/exec` **inchangée** fonctionne toujours ; le code est sur GitHub ;
`DEPLOY.md` rempli (Script ID, **DEPLOYMENT_ID**, URL, Sheet ID). ✅ → passe à la **Phase finale**.

> **Migration dans un dossier Drive — possible et sans risque.** Déplacer le Google Sheet (et
> le fichier du script) dans un dossier **ne change ni les IDs ni l'URL `/exec`** (la position
> Drive est indépendante). Le plus simple : l'utilisateur les **glisse** dans le dossier voulu
> dans Drive (1 geste) ; un script *bound* (attaché au Sheet) suit automatiquement le Sheet.
> C'est aussi automatisable via une fonction `DriveApp` one-shot, mais le glisser-déposer suffit.

---

### Phase finale — SEULEMENT MAINTENANT, l'application

- **Nouveau projet** : « **Décris-moi l'application que tu veux créer** : à quoi elle sert, qui
  l'utilise, quelles informations elle affiche et enregistre. »
- **Projet existant** : « **Que veux-tu modifier ou ajouter** à l'app existante ? »

Puis construis / fais évoluer de façon **incrémentale** en suivant la boucle du §4 (adapter
`Code.js`/`Index.html`, tester sur `/dev`, `commit` + `push`, `version` + `redeploy` sur le
**DEPLOYMENT_ID** enregistré).

---

## 4. La boucle d'itération (à chaque modification)

Deux historiques à tenir : **Git** (le code) et **Apps Script** (le déploiement).

```
Modifier le code
   │
   ├─►  clasp push                          # met à jour la version de TEST (/dev), instantané
   │
   ├─►  Tester sur l'URL /dev               # clasp open-web-app, ou éditeur → Déployer → Tester
   │
   └─►  Quand c'est bon :
        git add -A && git commit -m "…"      # historique du code
        git push                             # → GitHub
        clasp version "…"                    # → numéro <num> (garde la même description que le commit)
        clasp redeploy <DEPLOYMENT_ID> -V <num> -d "<Nom du projet> — app web"   # → publie sur /exec
```

- **`/dev`** = bac à sable (reflète le dernier `push`). **`/exec`** = l'app publiée, elle
  ne change **que** par un `redeploy`, et son URL **ne change jamais**.
- **Astuce cache** : juste après un `redeploy`, un appareil peut afficher l'ancien code
  (cache navigateur). Forcer avec `?cb=1` à la fin de l'URL, ou vider le cache du site.
- Garde la **même formulation** entre le message de commit et la description `clasp version` :
  les deux historiques restent alignés et faciles à relire.

---

## 5. Le contenu du repo

Le squelette est déjà en place — adapte-le, ne repars pas de zéro :

| Fichier | Rôle |
|---|---|
| `AGENTS.md` | Ce guide. |
| `appsscript.json` | Manifeste : fuseau Europe/Paris, web-app `executeAs USER_DEPLOYING`, `access DOMAIN`. |
| `Code.js` | Backend : `doGet` sert l'app, lecture/écriture du Sheet **par lots + cache + verrou**, onglets auto-créés. À adapter (`TABS`, `getData`, `saveEntry`). |
| `Index.html` | Front mono-page : appelle le backend via `google.script.run`, `JSON.parse` des réponses. |
| `SECRETS.md` | Liste des Propriétés du script à régler (sans valeurs) + où les trouver. |
| `DEPLOY.md` | Mémo de déploiement du projet (IDs + commande de publication pré-remplie). |
| `.gitignore` | Exclut jetons clasp, `node_modules`, sauvegardes, tout fichier de secret. |
| `.clasp.json` | Créé par `clasp create` ; associe le dossier au projet Apps Script. |

---

## 6. Performance : parler au Google Sheet efficacement

Le Sheet est pratique mais **lent** : chaque appel est un aller-retour réseau. Une app qui
rame, c'est presque toujours **trop d'appels au Sheet**. Règles, déjà appliquées dans `Code.js` :

- **Lire par lots.** `getDataRange().getValues()` lit tout l'onglet en **un** appel.
  Ne **jamais** lire cellule par cellule dans une boucle (`getRange(i,j).getValue()`) —
  c'est 10 à 100× plus lent. → helper `readRows_()`.
- **Écrire par lots.** Pour plusieurs lignes, construis un tableau 2D et fais **un seul**
  `range.setValues(...)`, plutôt que des `appendRow` en boucle.
- **Ouvrir le classeur une seule fois** par exécution et réutiliser la référence
  (`openById` est coûteux). → helper `ss_()`.
- **Cacher** ce qui change peu (config, listes de personnes) avec `CacheService`, pour
  éviter de retoucher le Sheet à chaque requête. → helper `cachedJson_()`.
- **Verrouiller les écritures concurrentes** (plusieurs tablettes en même temps) avec
  `LockService`, pour que deux envois n'écrasent pas la même ligne. → dans `saveEntry`.
- Éviter `SpreadsheetApp.flush()` sauf nécessité ; préférer `PropertiesService`/`CacheService`
  pour un petit état plutôt qu'un aller-retour Sheet.

---

## 7. Gérer les secrets

1. Éditeur Apps Script (`clasp open-script`) → ⚙️ **Paramètres du projet** →
   **Propriétés du script** → *Ajouter une propriété*.
2. **Clé** = le nom utilisé dans le code (ex. `BREVO_API_KEY`). **Valeur** = prise dans
   **1Password** (coffre `<VAULT_1PASSWORD>`). Voir `SECRETS.md`.
3. Dans le code, lire ainsi (jamais la valeur en dur) :
   ```js
   const KEY = PropertiesService.getScriptProperties().getProperty('BREVO_API_KEY') || '';
   ```
4. **Jamais** de valeur de secret dans un fichier suivi par Git, un message, un README.
   Si un secret a fuité → **préviens FX immédiatement** (révocation + régénération).

---

## 8. Recettes optionnelles

> N'ajoute que ce dont tu as besoin. Chaque recette introduit un **nouveau scope OAuth** →
> applique la **règle n°9** (tester dans l'éditeur + accepter l'autorisation) **avant** de redéployer.

### 8.a — Envoyer un e-mail (`notifications@gong-galaxy.com`)

```js
/* ============ RECIPE: EMAIL NOTIFICATION ============ */
// In Workspace, e-mail is sent AS the account running the script (the deployer). To send
// from the shared address notifications@gong-galaxy.com, that address must be set up as a
// "Send mail as" alias / delegation on the running account (one-time Workspace admin task
// by FX). With the alias in place, use the {from: ...} option; without it, drop {from} and
// mail goes out from the deployer's own address.
const NOTIF_FROM = 'notifications@gong-galaxy.com';
const NOTIF_TO   = 'fxd@gong-galaxy.com'; // or read recipients from a Sheet tab

function sendNotification_(subject, body) {
  GmailApp.sendEmail(NOTIF_TO, subject, body, { from: NOTIF_FROM, name: 'GONG' });
}

// Run once from the editor to grant the Gmail permission, then check the inbox.
function testEmail() {
  sendNotification_('Test GONG', 'Ceci est un test.');
}
```

> Si l'alias `notifications@` n'est pas encore configuré : utilise
> `MailApp.sendEmail(NOTIF_TO, subject, body)` (scope plus léger, expéditeur = le
> déployeur), et demande à FX de mettre en place l'alias si l'expéditeur `notifications@`
> est requis.

### 8.b — Alerte SMS (Brevo) — pack complet (envoi + contrôle quotidien + repli e-mail)

```js
/* ============ RECIPE: SMS ALERT (Brevo) + DAILY CHECK + EMAIL FALLBACK ============ */
// API key lives in Script Properties (BREVO_API_KEY), value copied from 1Password.
// NEVER hard-code it: a committed key gets auto-revoked → silent SMS outage.
const BREVO_API_KEY = (function () {
  try { return PropertiesService.getScriptProperties().getProperty('BREVO_API_KEY') || ''; }
  catch (e) { return ''; }
})();
const BREVO_SMS_URL = 'https://api.brevo.com/v3/transactionalSMS/sms';
const SMS_SENDER    = 'GONG';                // alphanumeric sender, max 11 chars
const ALERT_EMAIL   = 'fxd@gong-galaxy.com'; // fallback when NO SMS can be sent

// Send one SMS. Returns true on success. A French mobile "06…" is normalised to "336…".
// Falls back to an alert e-mail if the key is missing or the API call fails.
function sendSms_(phone, content) {
  if (!BREVO_API_KEY) {
    MailApp.sendEmail(ALERT_EMAIL, 'SMS non envoyé (clé absente)', content);
    return false;
  }
  var recipient = String(phone).replace(/\D/g, '').replace(/^0/, '33');
  var res = UrlFetchApp.fetch(BREVO_SMS_URL, {
    method: 'post',
    contentType: 'application/json',
    headers: { 'api-key': BREVO_API_KEY },
    muteHttpExceptions: true,
    payload: JSON.stringify({
      type: 'transactional', unicodeEnabled: false,
      sender: SMS_SENDER, recipient: recipient, content: content
    })
  });
  var ok = res.getResponseCode() < 300;
  if (!ok) MailApp.sendEmail(ALERT_EMAIL, 'Échec envoi SMS', res.getContentText());
  return ok;
}

// Target of the daily trigger. Put your condition here (e.g. "today's action is missing
// → alert every manager listed in a Sheet tab").
function dailyCheck() {
  // TODO: implement the condition, then call sendSms_(number, message) as needed.
}

// Run once from the editor (accept the authorisation) to install the daily trigger.
// Removes any existing copy first so triggers never pile up.
function setupDailyTrigger() {
  ScriptApp.getProjectTriggers().forEach(function (t) {
    if (t.getHandlerFunction() === 'dailyCheck') ScriptApp.deleteTrigger(t);
  });
  ScriptApp.newTrigger('dailyCheck').timeBased().atHour(20).everyDays(1).create();
}
```

---

## 9. Pièges connus (mémo rapide)

| Symptôme | Cause | Solution |
|---|---|---|
| Données « vides » alors que le Sheet est rempli | `getActiveSpreadsheet()` vise le mauvais classeur | Toujours `openById(SHEET_ID)` (règle n°6) |
| Une liste arrive `null` dans le navigateur | `google.script.run` sérialise mal les tableaux d'objets | Renvoyer une **chaîne JSON**, `JSON.parse` côté client (règle n°7) |
| L'app rame | Trop d'appels au Sheet | Lire/écrire **par lots**, cacher les listes (§6) |
| `/exec` en erreur d'autorisation après une modif | Nouveau scope OAuth non accepté | Tester dans l'éditeur, accepter, **puis** redéployer (règle n°9) |
| Une modif n'apparaît pas pour les utilisateurs | `clasp push` seul ne publie pas | `version` **puis** `redeploy` (§4) |
| L'appareil affiche l'ancien code après un redeploy | Cache navigateur | Ouvrir l'URL avec `?cb=1` |
| L'URL publique a changé (QR/liens morts) | `clasp deploy` a créé un **nouveau** déploiement | Toujours `redeploy` le même `DEPLOYMENT_ID` (règle n°2) |
| Fonction qui pollue le menu *Exécuter* | Fonction « publique » | Suffixer son nom par `_` → privée |
| `git push` refusé | Pas connecté | `gh auth login` (§2) |

---

## 10. Checklist avant de dire « c'est prêt »

- [ ] `clasp push` sans erreur, testé sur l'URL **/dev**.
- [ ] `git commit` + `git push` faits (le code est sur GitHub).
- [ ] `clasp version` créé, `clasp redeploy <DEPLOYMENT_ID> -V <num>` fait — **/exec** fonctionne.
- [ ] Aucun secret dans le code / Git ; tout en **Propriétés du script** (valeurs 1Password).
- [ ] Onglets du Sheet auto-créés ; personnes/droits/données modifiables **sans redéployer**.
- [ ] Appels au Sheet **par lots** ; listes chaudes **cachées** (§6).
- [ ] Commentaires de code en anglais, textes visibles en français.
- [ ] `DEPLOY.md` à jour (script ID, sheet ID, **deployment ID**, URL /exec, repo GitHub).
- [ ] Si e-mail/SMS/Drive : autorisation acceptée dans l'éditeur **avant** le redeploy.

---

## 11. Quand demander de l'aide à FX

Arrête-toi et renvoie vers FX (`fxd@gong-galaxy.com`) avant / en cas de :

- **créer ou supprimer un déploiement** (au-delà du tout premier), ou tout changement
  susceptible de **modifier l'URL publique** ;
- **alias d'envoi** `notifications@gong-galaxy.com` à mettre en place (admin Workspace) ;
- **valeur de secret** à obtenir/renouveler (1Password), ou **secret potentiellement fuité** ;
- passage envisagé en `access: ANYONE` (app ouverte hors domaine) ;
- doute sur quoi que ce soit d'**irréversible** côté Google ou GitHub.

---

<!--
NOTES POUR FX (à garder comme aide-mémoire, ou retirer avant diffusion large) :
  À renseigner avant de publier le repo squelette :
    <ORG_OU_FX>/appsscript-starter-kit  → emplacement du repo template sur GitHub
    <VAULT_1PASSWORD>                    → coffre 1Password des secrets
  Renseignés par le collaborateur au bootstrap :
    <TON_PRÉNOM>, <ID_DOSSIER_PERSO_DRIVE>, <ID_DU_SOUS_DOSSIER_DRIVE>,
    <ID_DU_GOOGLE_SHEET>, <SCRIPT_ID>, <DEPLOYMENT_ID>, <URL_EXEC>, <URL_DU_REPO_GITHUB>
  À confirmer : orthographe exacte de l'adresse (notification@ vs notifications@).
  Côté FX, une fois : marquer le repo GitHub comme "Template repository" (Settings →
  Template repository) pour que "Use this template" / gh --template fonctionne.
-->
