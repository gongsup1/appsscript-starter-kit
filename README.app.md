# <Nom de l'app>

<Une ou deux phrases : à quoi sert l'app, et pour qui.>

> Ce fichier est tenu à jour par l'IA à chaque mise en production. Il sert à quiconque doit reprendre ou dépanner l'app (un collègue, FX) : tout ce qu'il faut savoir est ici ou dans `DEPLOY.md`.

## Accès

| | Adresse | Pour qui |
|---|---|---|
| **PROD** | <URL_EXEC_PROD> | les utilisateurs |
| **DEV** | <URL_EXEC_DEV> | le développeur et ses testeurs (bandeau DEV, notifications redirigées vers le développeur) |

- **Dossier de l'app (Drive partagé)** : <URL_DU_DOSSIER_DE_L_APP>
- **Google Sheets** : PROD (vraies données) <URL_SHEET_PROD> ; DEV (données de test) <URL_SHEET_DEV>
- **Code** : ce dépôt GitHub, qui fait référence. Côté Google : *Extensions → Apps Script* depuis chaque Sheet <ou, pour un script autonome : son fichier dans le dossier de l'app>. On ne modifie jamais le code dans l'éditeur en ligne.
- **Responsable de l'app** : <Prénom Nom> (<e-mail>)
- **Référent technique** : FX (fxd@gong-galaxy.com)

## Ce que fait l'app

- <fonctionnalité 1>
- <fonctionnalité 2>

## Données (onglets du Google Sheet)

| Onglet | Contenu | Modifiable à la main ? |
|---|---|---|
| <ONGLET> | <description> | <oui / non> |

## Automatismes

| Quoi | Quand | Destinataires en PROD |
|---|---|---|
| <ex. relance par e-mail> | <ex. chaque jour à 9 h> | <ex. managers listés dans l'onglet EQUIPE> |

<Écrire « Aucun » s'il n'y en a pas. En DEV, toutes les notifications partent vers le développeur.>

## Faire évoluer l'app

- **Sur un nouveau Mac** (ou pour reprendre l'app d'un collègue) : lancer la commande d'installation du kit, puis donner le nom `<nom-du-projet>` ; l'IA reprend le projet depuis ce dépôt.
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/gongsup1/appsscript-starter-kit/main/bootstrap.sh)"
  ```
- **Sur le Mac où le projet existe déjà** : app Claude, onglet Code, le projet est dans la liste.
- Règles, publication (DEV puis PROD) et retour arrière : `AGENTS.md` et `DEPLOY.md`.

## Journal des versions (PROD)

| Version | Date | Changements |
|---|---|---|
| <v1> | <JJ/MM/AAAA> | <mise en service> |
