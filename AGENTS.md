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
- **Remplis toi-même tous les fichiers** (`DEPLOY.md`, nom du projet, IDs, README du projet…)
  à partir des réponses de la conversation. L'utilisateur **n'édite jamais** un fichier à la main
  — son seul geste « fichier » est de **coller une valeur de secret** dans l'éditeur (§7), que tu
  guides pas à pas.
- **Demande confirmation AVANT toute action irréversible côté Google/GitHub** : premier
  déploiement, suppression d'un fichier/onglet Drive, envoi d'un **vrai** SMS/e-mail à
  des destinataires réels (teste d'abord sur toi-même). Un dépôt public est **interdit** (règle 10).
- Si quelque chose sort du périmètre (nouveau scope sensible, changement d'URL publique,
  doute sur un secret) → **arrête-toi et renvoie vers FX** (§11).
- **Respecte les 10 règles d'or ci-dessous sans exception.**

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

## 1. Les 10 règles d'or (non négociables)

1. **Secrets → jamais dans le code ni dans Git.** Clés API, mots de passe vivent dans les
   **Propriétés du script** (valeurs prises dans **1Password**, coffre `Vibe-coding`).
   Voir §7. *Une clé committée reste dans l'historique Git pour toujours,
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
10. **Repos de projet TOUJOURS privés — JAMAIS de dépôt public.** Tout `gh repo create` se fait
    avec `--private` dans l'org `gongsup1` ; après création, **vérifie** que la visibilité est
    bien `private` (`gh repo view gongsup1/<projet> --json visibility`). Ne crée **jamais** un
    repo public, ne bascule **jamais** un repo en public (le code porte des références internes :
    IDs de Sheet, logique métier, listes de personnes). Le **seul** dépôt public est le template
    `gongsup1/appsscript-starter-kit`, que tu ne crées pas. Au moindre doute → privé + FX (§11).

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

> **Membre de l'org.** Les projets sont créés **dans l'organisation GitHub `gongsup1`** (owner
> `dev@gong-galaxy.com`), **pas** dans le compte perso — ainsi GONG possède et peut auditer
> tous les repos. FX **invite** le collaborateur comme **membre** de l'org (une fois). Tant
> que l'invitation n'est pas acceptée, `gh repo create gongsup1/…` échouera → l'accepter d'abord.

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

**A1. Dépôt GitHub dans l'org** (l'IA) — selon comment tu es arrivé :

- **Tu es passé par la commande d'install (ou un ZIP)** → les fichiers du squelette sont
  **déjà dans ton dossier local**. On crée le repo dans l'org **à partir de ces fichiers** :
  ```bash
  git init && git add -A && git commit -m "chore: squelette initial"
  gh repo create gongsup1/<nom-du-projet> --private --source=. --push
  ```
- **Terminal nu, sans les fichiers** → on instancie le template directement :
  ```bash
  gh repo create gongsup1/<nom-du-projet> --template gongsup1/appsscript-starter-kit --private --clone
  cd <nom-du-projet>
  ```

> Le repo du projet est **privé** et **dans l'org** ; seul le template
> `gongsup1/appsscript-starter-kit` est public.

**A2. Dossier Drive + Sheet** (humain) : ouvre le **dossier qui t'a été attribué** pour tes
projets — **FX t'en a partagé le lien** (c'est `<ID_DOSSIER_PERSO_DRIVE>`). **Dedans**, crée un
**sous-dossier** au nom du projet, puis **à l'intérieur** un **Google Sheet** vide. Copie l'**ID
du Sheet** depuis son URL : `https://docs.google.com/spreadsheets/d/`**`CET_ID`**`/edit`, et
donne-le à l'IA (avec l'**ID du dossier**).

> Le Sheet **doit** vivre dans ton dossier attitré : c'est là que FX peut le retrouver et
> l'auditer. L'IA **ne peut pas** créer ce dossier/Sheet à ta place — écrire dans Drive
> exige une autorisation Google qu'elle n'a pas (comme pour les secrets). Ces 2-3 clics
> restent le geste humain ; l'IA fait tout le reste.

**A3. Brancher + déployer le squelette** (l'IA, déploiement à confirmer) :
```bash
clasp create --type standalone --title "<Nom du projet>"
# dans Code.js : remplacer <ID_DU_GOOGLE_SHEET> (Sheet de A2) et <APP NAME>
clasp push
clasp version "v1 — squelette"                        # → numéro <num>
clasp deploy -V <num> -d "<Nom du projet> — app web"  # → note le DEPLOYMENT_ID (AKfyc…) = le SEUL
clasp open-web-app
```

**A4. Mémo + commit** : remplis `DEPLOY.md` ; **remplace le README** par un court README du projet
(titre = nom du projet, 1–2 lignes, pointe vers `DEPLOY.md` pour l'URL/IDs) ; **supprime
`bootstrap.sh`** s'il est présent (c'est l'installeur du template, inutile dans un projet). Puis
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
fichiers-guides (`AGENTS.md`, `CLAUDE.md`, `README.md`, `DEPLOY.md`, `.gitignore`). Puis :
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
gh repo create gongsup1/<nom-du-projet> --private --source=. --push
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
| `CLAUDE.md` | Une ligne `@AGENTS.md` : Claude Code ne lit que `CLAUDE.md`, cette ligne lui fait charger ce guide. Source unique (Codex lit `AGENTS.md` directement). |
| `appsscript.json` | Manifeste : fuseau Europe/Paris, web-app `executeAs USER_DEPLOYING`, `access DOMAIN`. |
| `Code.js` | Backend : `doGet` sert l'app, lecture/écriture du Sheet **par lots + cache + verrou**, onglets auto-créés. À adapter (`TABS`, `getData`, `saveEntry`). |
| `Index.html` | Front mono-page : appelle le backend via `google.script.run`, `JSON.parse` des réponses. |
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

## 7. Gérer les secrets (clés API, mots de passe)

Les secrets vivent dans les **Propriétés du script** — l'équivalent Apps Script d'un `.env`,
**côté Google, jamais dans le dépôt**. Apps Script n'a **pas** de `.env` ni de variables
d'environnement : **ni `clasp`, ni l'API, ni toi (l'IA) ne pouvez les écrire**. Tu prépares tout
le reste ; **coller la valeur est le SEUL geste humain** — et tu le **guides pas à pas**.

**Secrets de ce kit :**

| Clé (= nom de la Propriété) | Sert à | Valeur | Requis ? |
|---|---|---|---|
| `BREVO_API_KEY` | Envoi e-mails (§8a) et SMS (§8b) via Brevo | 1Password, coffre `Vibe-coding` → la clé Brevo **attribuée à l'utilisateur** (créée par le service informatique) | Oui si e-mail/SMS |

**Poser une clé — déroule ces étapes AVEC l'utilisateur**, à voix haute, une par une :

1. Ouvre l'éditeur : `clasp open-script` (ou <https://script.google.com>).
2. En bas à gauche : ⚙️ **Paramètres du projet**.
3. Section **Propriétés du script** → **Ajouter une propriété de script**.
4. **Propriété** (le nom, à taper **exactement**) : `BREVO_API_KEY`.
5. **Valeur** : ouvre **1Password** → coffre `Vibe-coding` → la clé Brevo attribuée à l'utilisateur,
   copie-la et **colle-la** (jamais tapée à la main, jamais notée ailleurs). Pas encore de clé ? → service informatique.
6. **Enregistrer les propriétés du script**. L'app la lira seule via `PropertiesService`.

Dans le code, lire ainsi (jamais la valeur en dur) :
```js
const KEY = PropertiesService.getScriptProperties().getProperty('BREVO_API_KEY') || '';
```

**Jamais** de valeur de secret dans un fichier suivi par Git, un message, un README : une clé
committée reste dans l'historique **et se fait révoquer** → panne silencieuse. En cas de fuite →
**préviens FX immédiatement** (révocation + régénération ; supprimer le fichier ne suffit pas).

---

## 8. Recettes optionnelles

> N'ajoute que ce dont tu as besoin. Chaque recette introduit un **nouveau scope OAuth** →
> applique la **règle n°9** (tester dans l'éditeur + accepter l'autorisation) **avant** de redéployer.

### 8.a — Envoyer un e-mail (Brevo, expéditeur `noreply@gong-galaxy.com`)

```js
/* ============ RECIPE: EMAIL (Brevo transactional) ============ */
// Same provider and key as the SMS recipe (§8.b): the Brevo API key lives in Script
// Properties (BREVO_API_KEY), value copied ONCE from 1Password (see §7). Brevo
// sends the mail AS noreply@gong-galaxy.com — a verified sender in Brevo, with the
// gong-galaxy.com domain authenticated (SPF/DKIM). No Google "Send as" alias is involved,
// and no SMTP password ever lives in an app.
// NEVER hard-code the key: a committed key gets auto-revoked → silent mail outage.
const BREVO_API_KEY  = PropertiesService.getScriptProperties().getProperty('BREVO_API_KEY') || '';
const BREVO_MAIL_URL = 'https://api.brevo.com/v3/smtp/email';
const MAIL_FROM      = { email: 'noreply@gong-galaxy.com', name: 'GONG' };

// Send one e-mail. Returns true on success. Pass htmlContent, OR switch to a Brevo template
// (templateId + params) so a non-dev can edit the wording/design in Brevo WITHOUT a redeploy.
function sendEmail_(to, subject, htmlContent) {
  if (!BREVO_API_KEY) return false;
  var res = UrlFetchApp.fetch(BREVO_MAIL_URL, {
    method: 'post',
    contentType: 'application/json',
    headers: { 'api-key': BREVO_API_KEY },
    muteHttpExceptions: true,
    payload: JSON.stringify({
      sender: MAIL_FROM,
      to: [{ email: to }],
      subject: subject,
      htmlContent: htmlContent
      // Template instead of htmlContent (edited in Brevo, no redeploy):
      // templateId: 3, params: { name: 'X' }
    })
  });
  return res.getResponseCode() < 300;
}

// Run once from the editor to grant the network permission (UrlFetch), then check the inbox.
function testEmail() {
  sendEmail_('fxd@gong-galaxy.com', 'Test GONG', '<p>Ceci est un test.</p>');
}
```

> **Réglage unique (admin, voir §11) :** dans Brevo, vérifier `noreply@gong-galaxy.com`
> comme **expéditeur** et **authentifier le domaine** `gong-galaxy.com` (SPF/DKIM). Le domaine
> envoie par **deux canaux** (Google pour les humains, Brevo pour les apps) → laisser **Google
> _et_ Brevo** dans le SPF du domaine. Tant que ce réglage n'est pas fait, les mails risquent le spam.

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
- **e-mail Brevo** : `noreply@gong-galaxy.com` à vérifier comme **expéditeur**, ou
  domaine `gong-galaxy.com` à authentifier (SPF/DKIM) dans Brevo — accès admin/DNS ;
- **valeur de secret** à obtenir/renouveler (1Password), ou **secret potentiellement fuité** ;
- passage envisagé en `access: ANYONE` (app ouverte hors domaine) ;
- doute sur quoi que ce soit d'**irréversible** côté Google ou GitHub.

---

<!--
NOTES POUR FX (à garder comme aide-mémoire, ou retirer avant diffusion large) :
  Placeholders du template :
    <ORG>=gongsup1     ✓ renseigné (org GitHub, owner dev@gong-galaxy.com)
    <REF>=main         ✓ renseigné (branche/tag servant bootstrap.sh)
    <VAULT_1PASSWORD>=Vibe-coding  ✓ renseigné (coffre 1Password ; clé Brevo par utilisateur autorisé, créée par le service info)
  Renseignés par le collaborateur au bootstrap :
    <TON_PRÉNOM>, <ID_DOSSIER_PERSO_DRIVE>, <ID_DU_SOUS_DOSSIER_DRIVE>,
    <ID_DU_GOOGLE_SHEET>, <SCRIPT_ID>, <DEPLOYMENT_ID>, <URL_EXEC>, <URL_DU_REPO_GITHUB>
  Côté FX, une fois :
    - créer l'org GitHub (owner dev@), publier gongsup1/appsscript-starter-kit en PUBLIC,
      le marquer "Template repository", autoriser les membres à créer des repos privés,
      inviter les collaborateurs comme membres ;
    - Brevo : vérifier l'expéditeur noreply@ + SPF/DKIM du domaine (Google ET Brevo).
-->
