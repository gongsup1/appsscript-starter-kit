# appsscript-starter-kit — squelette d'app Google Apps Script (GONG)

Repo **template** pour créer, en autonomie et **guidé par une IA**, une petite
application web interne : **back-end Google Apps Script**, **données dans un Google
Sheet**, **déploiement via `clasp`**, **historique sur GitHub**. Pensé pour des
collaborateurs **non-développeurs**.

## Comment ça marche

**En une commande** (Mac) — installe l'assistant IA, récupère le squelette et le lance :

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/gongsup1/appsscript-starter-kit/main/bootstrap.sh)"
```

Le script demande **quel assistant IA** (Claude Code ou Codex) et le **nom du projet**, crée le
dossier `~/coding-projects/<nom>`, y récupère le squelette, puis **ouvre l'assistant dessus**.
Pour **Claude Code, l'app desktop** s'ouvre directement sur le projet avec la phrase de départ
**déjà pré-remplie** — il ne reste qu'à appuyer sur **Entrée** :

> « Lis `AGENTS.md` et aide-moi à démarrer mon application. »

L'assistant suit **`AGENTS.md`** (chargé automatiquement — voir `CLAUDE.md`) et déroule tout :
connexions, création du repo **dans l'org** (privé), projet Apps Script, branchement du Google
Sheet, déploiement, puis itérations.

> **Sans la commande** (terminal déjà équipé) : `gh repo create gongsup1/<projet> --template
> gongsup1/appsscript-starter-kit --private --clone`, ouvrir le dossier avec l'IA, même phrase.

**Le point d'entrée du travail de l'IA, c'est [`AGENTS.md`](./AGENTS.md).**

## Contenu

| Fichier | Rôle |
|---|---|
| [`AGENTS.md`](./AGENTS.md) | Le guide que suit l'IA (règles d'or, bootstrap, boucle d'itération, performance, recettes). |
| [`CLAUDE.md`](./CLAUDE.md) | Une ligne (`@AGENTS.md`) : fait lire `AGENTS.md` à **Claude Code**, qui ne lit que `CLAUDE.md`. Source unique, partagée avec Codex. |
| `appsscript.json` | Manifeste Apps Script (fuseau Paris, web-app, accès domaine). |
| `Code.js` | Squelette back-end : sert l'app, lit/écrit le Sheet **par lots + cache + verrou**. |
| `Index.html` | Squelette front mono-page. |
| `SECRETS.md` | Quels secrets régler, et **où** trouver leurs valeurs (jamais dans le repo). |
| `DEPLOY.md` | Mémo de déploiement par projet (IDs + commande de publication). |
| `.gitignore` | Exclut jetons et tout fichier de secret. |
| `bootstrap.sh` | Commande d'install « une ligne » (Mac) : choisit l'assistant, installe Node + l'app (**Claude Code desktop** en cask, ou **Codex** CLI), récupère le squelette, ouvre l'assistant sur le projet. |

## Principes (résumé)

- **Le Sheet est la source de vérité** : données *et* droits, onglets auto-créés,
  modifiables sans redéployer.
- **Secrets jamais dans le code ni Git** → Propriétés du script (valeurs depuis 1Password).
- **Toujours redéployer le même déploiement** : l'URL `/exec` ne change jamais.
- **Double versioning** : Git (le code) + Apps Script (`version`/`redeploy`).
- **Code commenté en anglais, doc et interface en français.**

## Prérequis

Node + `clasp` (≥ 3.3), `git`, `gh` (GitHub CLI). Un compte Google Workspace
`@gong-galaxy.com` et un compte GitHub **membre de l'org GONG**. Détails et commandes dans
`AGENTS.md` §2.

---

## Mise en place (pour FX, une seule fois)

- **Organisation GitHub** : créer l'org (owner `dev@gong-galaxy.com`). Y publier ce repo
  **`gongsup1/appsscript-starter-kit` en PUBLIC** (le `bootstrap.sh` est servi par son URL brute)
  et le marquer **« Template repository »** (*Settings* → cocher). Autoriser les membres à
  **créer des repos privés** dans l'org, puis **inviter** les collaborateurs comme membres :
  leurs projets naîtront **dans l'org**, privés, possédés et auditables par GONG.
- **`bootstrap.sh`** : `<ORG>`/`<REF>` déjà renseignés (**`gongsup1`** / **`main`**). La commande
  d'install pointe sur `raw.githubusercontent.com/gongsup1/appsscript-starter-kit/main/bootstrap.sh`.
- **Dossiers Drive** : créer un dossier attitré par collaborateur, lui donner l'accès en
  écriture, et lui transmettre l'**ID** du dossier.
- **1Password** : ranger les clés/API (ex. Brevo) dans le coffre `Vibe-coding` et
  donner l'accès aux personnes concernées. Les valeurs se recopient dans les Propriétés du
  script de chaque projet — jamais dans le repo.
- **E-mail & SMS (Brevo)** : les apps envoient via **un seul compte Brevo GONG**. Le **service
  informatique** crée **une clé API Brevo par utilisateur autorisé** et la range dans `Vibe-coding`
  (collée dans les Propriétés du script de ses projets — jamais dans le repo). Vérifier
  `noreply@gong-galaxy.com` comme **expéditeur** dans Brevo et **authentifier le domaine**
  `gong-galaxy.com` (SPF/DKIM) ; laisser **Google *et* Brevo** dans le SPF (le domaine envoie par
  les deux : Google pour les humains, Brevo pour les apps). **Aucun** alias « Envoyer en tant
  que » n'est nécessaire.
- **Placeholders** : tous renseignés — `<ORG>`=`gongsup1`, `<REF>`=`main`, `<VAULT_1PASSWORD>`=`Vibe-coding`.
