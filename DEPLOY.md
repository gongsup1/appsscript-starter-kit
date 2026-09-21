# Déploiement : `<NOM_DU_PROJET>`

> Ce fichier est le **mémo de déploiement du projet**. Il est rempli une fois, au
> premier déploiement, puis sert de garde-fou : la commande de publication y est
> pré-remplie avec le **bon** identifiant de déploiement (celui qu'il ne faut jamais
> changer).

## Identifiants (à remplir au bootstrap)

| Clé | Valeur |
|---|---|
| Script ID | `<SCRIPT_ID>` |
| Sheet (URL ou ID) | `<URL_OU_ID_DU_GOOGLE_SHEET>` |
| Dossier Drive du projet | `<ID_DU_SOUS_DOSSIER_DRIVE>` |
| **Deployment ID (NE JAMAIS EN CRÉER UN AUTRE)** | `<DEPLOYMENT_ID>` |
| URL publique `/exec` (ne change jamais) | `<URL_EXEC>` |
| Repo GitHub | `<URL_DU_REPO_GITHUB>` |

> 🔑 Les **secrets** (clés API, mots de passe) ne se notent **jamais** ici : ils vivent dans les **Propriétés du script**. Mode d'emploi : `AGENTS.md` §7.

## Publier une modification

Toujours ces étapes, dans cet ordre (voir `AGENTS.md` §4) :

```bash
clasp push                                  # 1. envoie le code → version de TEST (/dev)
# … tester sur l'URL /dev …
git add -A && git commit -m "description"   # 2. historique Git
git push                                    # 3. → GitHub
clasp version "description"                  # 4. → note le numéro <num>
clasp redeploy <DEPLOYMENT_ID> -V <num> -d "<NOM_DU_PROJET> - app web"   # 5. → publie sur /exec
```

- ❌ **Jamais** `clasp deploy` (créerait une **nouvelle** URL → liens/QR morts).
- ❌ **Jamais** supprimer le déploiement `<DEPLOYMENT_ID>`.
- ⚠️ Nouvelle capacité (e-mail, Drive…) = nouveau scope OAuth : exécuter une fonction
  de test dans l'éditeur et **accepter l'autorisation AVANT** l'étape 5 (voir `AGENTS.md` règle n°9).
