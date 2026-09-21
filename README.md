# appsscript-starter-kit : squelette d'app Google Apps Script (GONG)

Repo **template** pour créer, en autonomie et **guidé par une IA**, une petite
application web interne : **back-end Google Apps Script**, **données dans un Google
Sheet**, **déploiement via `clasp`**, **historique sur GitHub**. Pensé pour des
collaborateurs **non-développeurs**.

## Comment ça marche

**En une commande** (Mac), qui installe l'assistant IA, récupère le squelette et le lance :

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/gongsup1/appsscript-starter-kit/main/bootstrap.sh)"
```

Le script demande **quel assistant IA** (Claude Code ou Codex) et le **nom du projet**, crée le dossier `~/coding-projects/<nom>`, y récupère le squelette, installe l'**app Claude (desktop)** et guide l'ouverture en deux temps, via le presse-papier :

1. le **chemin du dossier** est copié : dans l'app, onglet **Code** (pas Cowork) → **Select folder** → **Cmd+Shift+G** → **Cmd+V** → **Entrée** → valider ;
2. l'utilisateur appuie sur Entrée dans le Terminal, la **phrase de démarrage** est copiée : il la colle dans Claude.

> « Lis AGENTS.md et aide-moi à démarrer mon application (projet : `<nom>`, dossier : `<chemin>`). Vérifie d'abord que tu travailles bien dans ce dossier. »

La phrase porte le chemin attendu : si le mauvais dossier a été ouvert, l'IA le détecte et fait rouvrir le bon (`AGENTS.md`, étape 0).

> **Revenir sur un projet** plus tard : ouvre l'app Claude → onglet **Code** → il est dans tes
> **dossiers récents** (pas besoin du terminal).

L'assistant suit **`AGENTS.md`** (chargé automatiquement, voir `CLAUDE.md`) et déroule tout :
connexions, création du repo **dans l'org** (privé), projet Apps Script, branchement du Google
Sheet, déploiement, puis itérations.

> **Sans la commande** (terminal déjà équipé) : `gh repo create gongsup1/<projet> --template
> gongsup1/appsscript-starter-kit --private --clone`, ouvrir le dossier avec l'IA, même phrase.

> **Projet Apps Script déjà existant ?** L'IA le reprend aussi (Parcours B d'`AGENTS.md`) :
> import du code, mise sous Git dans l'org, et **migration dans ton dossier Drive attitré**,
> **sans changer son URL publique**.

**Le point d'entrée du travail de l'IA, c'est [`AGENTS.md`](./AGENTS.md).**

## Contenu

| Fichier | Rôle |
|---|---|
| [`AGENTS.md`](./AGENTS.md) | Le guide que suit l'IA (règles d'or, bootstrap, boucle d'itération, performance, recettes). |
| [`CLAUDE.md`](./CLAUDE.md) | Une ligne (`@AGENTS.md`) : fait lire `AGENTS.md` à **Claude Code**, qui ne lit que `CLAUDE.md`. Source unique, partagée avec Codex. |
| `appsscript.json` | Manifeste Apps Script (fuseau Paris, web-app, accès domaine). |
| `Code.js` | Squelette back-end : sert l'app, lit/écrit le Sheet **par lots + cache + verrou**. |
| `Index.html` | Squelette front mono-page. |
| `Styles.html`, `Header.html` | La charte graphique (copies de `design-system/brand.css` et `header.js`) sous la forme `.html` qu'Apps Script sait servir. |
| `design-system/` | Sources de la charte graphique : tokens, composants, en-tête `<app-header>`, règles d'usage, page d'aperçu. Reste en local. |
| `DEPLOY.md` | Mémo de déploiement par projet (IDs + commande de publication). |
| `.gitignore` | Exclut jetons et tout fichier de secret. |
| `.claspignore` | Empêche `clasp push` d'envoyer `design-system/` chez Google (ses sources feraient planter l'app côté serveur). |
| `bootstrap.sh` | Commande d'install « une ligne » (Mac) : choisit l'assistant, installe Node + l'**app Claude desktop** (cask `claude`, ou **Codex** CLI), récupère le squelette, ouvre l'app. |

## Principes (résumé)

- **Le Sheet est la source de vérité** : données *et* droits, onglets auto-créés,
  modifiables sans redéployer.
- **Secrets jamais dans le code ni Git** → Propriétés du script (aucun secret dans le kit pour l'instant).
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
- **E-mail** : rien à mettre en place. Les apps envoient avec `MailApp` (service Google natif), **depuis l'adresse du collaborateur** qui a déployé l'app. Quota Google : environ 1 500 destinataires par jour et par compte.
- **Clés API** (SMS, services tiers) : pas dans le kit pour l'instant. Le mode de transmission des clés aux collaborateurs reste à définir ; d'ici là, l'IA renvoie toute demande de ce type vers FX.
- **Placeholders** : tous renseignés : `<ORG>`=`gongsup1`, `<REF>`=`main`.
