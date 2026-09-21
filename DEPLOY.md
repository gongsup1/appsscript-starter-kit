# Déploiement : `<NOM_DU_PROJET>`

> Ce fichier est le **mémo de déploiement du projet**. Il est rempli une fois, à la mise en place, puis sert de garde-fou : les commandes de publication y sont pré-remplies avec les **deux seuls** identifiants de déploiement du projet (DEV et PROD), qu'il ne faut jamais changer.

## Identifiants (à remplir à la mise en place)

| | DEV | PROD |
|---|---|---|
| Projet Apps Script (Script ID) | `<SCRIPT_ID_DEV>` | `<SCRIPT_ID_PROD>` |
| Fichier clasp | `.clasp.json` (cible par défaut) | `.clasp.prod.json` (toujours `-P "$PWD/.clasp.prod.json"`) |
| Google Sheet (URL ou ID) | `<URL_OU_ID_SHEET_DEV>` | `<URL_OU_ID_SHEET_PROD>` |
| **Deployment ID : le SEUL, n'en créer JAMAIS d'autre** | `<DEPLOYMENT_ID_DEV>` | `<DEPLOYMENT_ID_PROD>` |
| Adresse de l'app `/exec` (ne change jamais) | `<URL_EXEC_DEV>` | `<URL_EXEC_PROD>` |

| | |
|---|---|
| Dossier Drive du projet | `<ID_DU_SOUS_DOSSIER_DRIVE>` |
| Repo GitHub | `<URL_DU_REPO_GITHUB>` |
| Design | Charte GONG (ou : « hors charte, choix de l'utilisateur le `<date>` », AGENTS.md B6.c) |

> 🔑 Les **secrets** (clés API, mots de passe) ne se notent **jamais** ici : ils vivent dans les **Propriétés du script**. Mode d'emploi : `AGENTS.md` §7.

## Reprise d'un projet existant (AGENTS.md, Parcours B)

À remplir seulement si le projet existait avant le kit.

| | |
|---|---|
| Rôle du projet d'origine | PROD (des personnes l'utilisent) ou DEV (prototype) |
| Version servie avant la reprise (**retour arrière**) | `<N>` |
| Étiquettes Git de sauvegarde | `origine-prod`, `origine-editeur`, branche `origine-copie-test` |
| Déclencheurs en place (PROD) | `<liste>` |
| Noms des Propriétés du script (jamais les valeurs) | `<liste>` |
| Autres adresses encore utilisées (signalées à FX) | `<liste ou « aucune »>` |

## Publier une modification

Toujours dans cet ordre (voir `AGENTS.md` §4). **Jamais** de modification dans l'éditeur Apps Script en ligne.

**1. En DEV, aussi souvent que nécessaire :**

```bash
git add -A && git commit -m "description" && git push
clasp push                                   # → projet DEV
clasp version "description"                  # → note le numéro <num>
clasp redeploy <DEPLOYMENT_ID_DEV> -V <num> -d "<NOM_DU_PROJET> (DEV)"
```

**2. En PROD, seulement sur demande de l'utilisateur, avec le code déjà testé en DEV :**

```bash
clasp -P "$PWD/.clasp.prod.json" push
clasp -P "$PWD/.clasp.prod.json" version "description"   # → note le numéro <num_prod>
clasp -P "$PWD/.clasp.prod.json" redeploy <DEPLOYMENT_ID_PROD> -V <num_prod> -d "<NOM_DU_PROJET> (PROD)"
git tag prod-vX && git push --tags
```

**Retour arrière PROD** (la nouveauté pose problème) : republier la version précédente, puis corriger en DEV.

```bash
clasp -P "$PWD/.clasp.prod.json" redeploy <DEPLOYMENT_ID_PROD> -V <version précédente> -d "<NOM_DU_PROJET> (PROD)"
```

- ❌ **Jamais** `clasp deploy` (créerait une **nouvelle** adresse → liens/QR morts, et un troisième déploiement).
- ❌ **Jamais** supprimer `<DEPLOYMENT_ID_DEV>` ni `<DEPLOYMENT_ID_PROD>`.
- ⚠️ Nouvelle capacité (e-mail, Drive…) = nouveau scope OAuth : exécuter une fonction de test dans l'éditeur **et accepter l'autorisation AVANT** le `redeploy`, en DEV puis en PROD (voir `AGENTS.md` règle n°9).
