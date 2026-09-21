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

Le script demande **quel assistant IA** (Claude Code ou Codex) et le **nom du projet**, crée le dossier `~/coding-projects/<nom>`, y récupère le squelette, installe l'**app Claude (desktop)** puis **l'ouvre directement sur le projet** (onglet Code), la phrase de démarrage déjà écrite. L'utilisateur n'a plus qu'à appuyer sur **Entrée** dans Claude :

> « Lis AGENTS.md et aide-moi à démarrer mon application (projet : `<nom>`, dossier : `<chemin>`). Vérifie d'abord que tu travailles bien dans ce dossier. »

L'ouverture passe par le lien `claude://code/new?folder=…&q=…` de l'app Claude (celui de son action Finder « New Claude Code Session Here »). Ce lien n'est pas documenté publiquement : le script affiche un plan B manuel (onglet Code → Select folder, phrase dans le presse-papier). La phrase porte le chemin attendu : si le mauvais dossier a été ouvert, l'IA le détecte et rouvre le bon (`AGENTS.md`, étape 0).

> **Une seule règle** : pour **démarrer** (nouveau projet, ou projet existant pas encore sur ce Mac), la commande ci-dessus ; pour **continuer** un projet, l'app Claude → onglet **Code** → le projet est dans la liste (pas besoin du terminal).

L'assistant suit **`AGENTS.md`** (chargé automatiquement, voir `CLAUDE.md`) et déroule tout : connexions, création du repo **dans l'org** (privé), les **deux environnements DEV et PROD** (deux Google Sheets, chacun avec son projet Apps Script **rattaché** : le code vit dans le Sheet et le suit dans les dossiers Drive ; un déploiement chacun), puis itérations : on publie en DEV, on teste, et la PROD suit sur demande.

> **Sans la commande** (terminal déjà équipé) : `gh repo create gongsup1/<projet> --template
> gongsup1/appsscript-starter-kit --private --clone`, ouvrir le dossier avec l'IA, même phrase.

> **Projet Apps Script déjà existant ?** L'IA le reprend aussi (Parcours B d'`AGENTS.md`, l'étape critique) : tout est **sauvegardé dans Git avant la moindre modification**, le projet actuel devient la PROD (même adresse, mêmes données) si des gens l'utilisent, un DEV est créé à côté, le code est remis aux bonnes pratiques **en DEV**, et la PROD ne change qu'une fois le DEV validé, avec retour arrière immédiat possible. Le design : migration vers la charte GONG ou maintien, au choix de l'utilisateur.

**Le point d'entrée du travail de l'IA, c'est [`AGENTS.md`](./AGENTS.md).**

## Contenu

| Fichier | Rôle |
|---|---|
| [`AGENTS.md`](./AGENTS.md) | Le guide que suit l'IA (règles d'or, bootstrap, boucle d'itération, performance, recettes). |
| [`CLAUDE.md`](./CLAUDE.md) | Une ligne (`@AGENTS.md`) : fait lire `AGENTS.md` à **Claude Code**, qui ne lit que `CLAUDE.md`. Source unique, partagée avec Codex. |
| `appsscript.json` | Manifeste Apps Script (fuseau Paris, web-app, accès domaine). |
| `Env.js` | **DEV / PROD** : identifie l'environnement (`ENV` = `'DEV'` ou `'PROD'`, calculé depuis l'ID du projet), ouvre le bon Sheet, réserve les tests et le « voir en tant que » au DEV. |
| `Code.js` | Squelette back-end : sert l'app, lit/écrit le Sheet de l'environnement **par lots + cache + verrou**. |
| `Index.html` | Squelette front mono-page ; bandeau DEV, bouton de test et « voir en tant que » en DEV seulement. |
| `Styles.html`, `Header.html` | La charte graphique (copies de `design-system/brand.css` et `header.js`) sous la forme `.html` qu'Apps Script sait servir. |
| `design-system/` | Sources de la charte graphique : tokens, composants, en-tête `<app-header>`, règles d'usage, page d'aperçu. Reste en local. |
| `DEPLOY.md` | Mémo de déploiement par projet : IDs DEV et PROD, publication, retour arrière. |
| `.gitignore` | Exclut jetons et tout fichier de secret. |
| `.claspignore` | Empêche `clasp push` d'envoyer `design-system/` chez Google (ses sources feraient planter l'app côté serveur). |
| `bootstrap.sh` | Commande d'install « une ligne » (Mac) : choisit l'assistant, installe Node + l'**app Claude desktop** (cask `claude`, ou **Codex** CLI), récupère le squelette, ouvre l'app sur le projet. |

## Principes (résumé)

- **Le Sheet est la source de vérité** : données *et* droits, onglets auto-créés,
  modifiables sans redéployer.
- **Secrets jamais dans le code ni Git** → Propriétés du script (aucun secret dans le kit pour l'instant). Dès qu'un secret ou une clé API apparaît, l'IA demande si l'utilisateur est absolument certain qu'il n'y a aucun risque ; au moindre doute, e-mail à `dev@gong-galaxy.com`.
- **Deux environnements, DEV et PROD, jamais un de plus** : un seul code, deux projets Apps Script jumeaux, chacun avec son Sheet et **un seul** déploiement. On publie en DEV, on teste, puis la PROD reçoit le même code sur demande. En DEV, les notifications partent vers le développeur et les outils de test sont disponibles ; en PROD, jamais. Les adresses `/exec` ne changent jamais.
- **Le code vit dans son Google Sheet** : un nouveau projet Apps Script, DEV comme PROD, est **rattaché** à son Sheet (*Extensions → Apps Script*). Un projet repris reste tel qu'il est (rattaché ou autonome), pour ne pas changer son adresse.
- **Tout vit dans le Drive partagé GONG** : chaque app a son dossier, où se trouvent ses Sheets et ses éventuels scripts autonomes. Les fichiers appartiennent à GONG, FX y a accès d'office, et un collaborateur absent ne bloque jamais la maintenance de son app. Vérifié avec l'utilisateur avant la création des projets et avant toute mise en PROD.
- **Double versioning** : Git (le code) + Apps Script (`version`/`redeploy`).
- **Code commenté en anglais, doc et interface en français.**

## Prérequis

Node + `clasp` (≥ 3.3), `git`, `gh` (GitHub CLI). Un compte Google Workspace
`@gong-galaxy.com` et un compte GitHub **membre de l'org GONG**. Détails et commandes dans
`AGENTS.md` §2.

---

## Pour FX : comportements à connaître

- **Filet de sécurité, non enseigné** : si quelqu'un relance la commande avec le nom d'un projet déjà présent dans `~/coding-projects/`, le script le rouvre dans Claude (phrase « On reprend mon projet… ») au lieu d'échouer ou de créer un doublon. Rien n'est téléchargé ni modifié.
- **Plan B affiché par le script** : l'ouverture directe passe par le lien non documenté `claude://code/new`. S'il cesse de marcher après une mise à jour de l'app Claude, l'utilisateur a les instructions manuelles à l'écran ; il faudra alors revoir le script.

## Mise en place (pour FX, une seule fois)

- **Organisation GitHub** : créer l'org (owner `dev@gong-galaxy.com`). Y publier ce repo
  **`gongsup1/appsscript-starter-kit` en PUBLIC** (le `bootstrap.sh` est servi par son URL brute)
  et le marquer **« Template repository »** (*Settings* → cocher). Autoriser les membres à
  **créer des repos privés** dans l'org, puis **inviter** les collaborateurs comme membres :
  leurs projets naîtront **dans l'org**, privés, possédés et auditables par GONG.
- **`bootstrap.sh`** : `<ORG>`/`<REF>` déjà renseignés (**`gongsup1`** / **`main`**). La commande
  d'install pointe sur `raw.githubusercontent.com/gongsup1/appsscript-starter-kit/main/bootstrap.sh`.
- **Drive partagé des apps GONG** : le créer une fois et y ajouter chaque collaborateur comme **Gestionnaire de contenu**. Chaque app y a son dossier (créé par le collaborateur au démarrage du projet). Déplacer un fichier dans ce Drive partagé ne change ni son ID ni l'adresse de l'app.
- **E-mail** : rien à mettre en place. Les apps envoient avec `MailApp` (service Google natif), **depuis l'adresse du collaborateur** qui a déployé l'app. Quota Google : environ 1 500 destinataires par jour et par compte.
- **Clés API** (SMS, services tiers) : pas dans le kit pour l'instant. Le mode de transmission des clés aux collaborateurs reste à définir ; d'ici là, l'IA fait envoyer toute demande de ce type à `dev@gong-galaxy.com`. **Cette boîte doit être surveillée.**
- **Placeholders** : tous renseignés : `<ORG>`=`gongsup1`, `<REF>`=`main`.
