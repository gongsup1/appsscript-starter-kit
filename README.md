# appsscript-starter-kit — squelette d'app Google Apps Script (GONG)

Repo **template** pour créer, en autonomie et **guidé par une IA**, une petite
application web interne : **back-end Google Apps Script**, **données dans un Google
Sheet**, **déploiement via `clasp`**, **historique sur GitHub**. Pensé pour des
collaborateurs **non-développeurs**.

## Comment ça marche

1. On part d'une **copie** de ce repo (bouton **« Use this template »** sur GitHub, ou
   `gh repo create <projet> --template <ORG_OU_FX>/appsscript-starter-kit --private --clone`).
2. On ouvre le dossier avec **Claude Code** (ou Codex/Cursor…) et on écrit :
   > « Lis `AGENTS.md` et aide-moi à démarrer mon application. »
3. L'IA suit **`AGENTS.md`** et déroule tout : connexions, création du projet Apps Script,
   branchement du Google Sheet, déploiement, puis itérations.

**Le point d'entrée, c'est [`AGENTS.md`](./AGENTS.md).** Tout est là.

## Contenu

| Fichier | Rôle |
|---|---|
| [`AGENTS.md`](./AGENTS.md) | Le guide que suit l'IA (règles d'or, bootstrap, boucle d'itération, performance, recettes). |
| `appsscript.json` | Manifeste Apps Script (fuseau Paris, web-app, accès domaine). |
| `Code.js` | Squelette back-end : sert l'app, lit/écrit le Sheet **par lots + cache + verrou**. |
| `Index.html` | Squelette front mono-page. |
| `SECRETS.md` | Quels secrets régler, et **où** trouver leurs valeurs (jamais dans le repo). |
| `DEPLOY.md` | Mémo de déploiement par projet (IDs + commande de publication). |
| `.gitignore` | Exclut jetons et tout fichier de secret. |

## Principes (résumé)

- **Le Sheet est la source de vérité** : données *et* droits, onglets auto-créés,
  modifiables sans redéployer.
- **Secrets jamais dans le code ni Git** → Propriétés du script (valeurs depuis 1Password).
- **Toujours redéployer le même déploiement** : l'URL `/exec` ne change jamais.
- **Double versioning** : Git (le code) + Apps Script (`version`/`redeploy`).
- **Code commenté en anglais, doc et interface en français.**

## Prérequis

Node + `clasp` (≥ 3.3), `git`, `gh` (GitHub CLI). Un compte Google Workspace
`@gong-galaxy.com` et un compte GitHub. Détails et commandes dans `AGENTS.md` §2.

---

## Mise en place (pour FX, une seule fois)

- **Publier ce repo** sous `<ORG_OU_FX>` et le marquer **« Template repository »**
  (GitHub → *Settings* → cocher *Template repository*), pour que « Use this template » /
  `gh --template` fonctionne.
- **Dossiers Drive** : créer un dossier attitré par collaborateur, lui donner l'accès en
  écriture, et lui transmettre l'**ID** du dossier.
- **1Password** : ranger les clés/API (ex. Brevo) dans le coffre `<VAULT_1PASSWORD>` et
  donner l'accès aux personnes concernées. Les valeurs se recopient dans les Propriétés du
  script de chaque projet — jamais dans le repo.
- **Alias e-mail** : si les apps doivent envoyer depuis `notifications@gong-galaxy.com`,
  configurer l'alias « Envoyer en tant que » / la délégation côté Workspace (voir
  `AGENTS.md` §8a).
- Renseigner les valeurs `<ORG_OU_FX>` et `<VAULT_1PASSWORD>` dans `AGENTS.md`, `README.md`
  et `SECRETS.md` avant diffusion.
