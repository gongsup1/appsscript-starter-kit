# Secrets du projet — `<NOM_DU_PROJET>`

> ⚠️ **Aucune valeur de secret ne va dans ce fichier ni nulle part dans le repo.**
> Ce fichier ne fait que **lister** les secrets à régler et **où trouver leur valeur**.

Les secrets se règlent dans les **Propriétés du script** :
éditeur Apps Script (`clasp open-script`) → ⚙️ **Paramètres du projet** →
**Propriétés du script** → *Ajouter une propriété*.
Les **valeurs** se récupèrent dans **1Password** (coffre `<VAULT_1PASSWORD>`).

| Clé (= nom de la Propriété du script) | À quoi ça sert | Où trouver la valeur | Requis ? |
|---|---|---|---|
| `BREVO_API_KEY` | Envoi de SMS via Brevo (recette §8b d'`AGENTS.md`) | 1Password → `<VAULT_1PASSWORD>` → « Brevo API » | Seulement si SMS |

## Envoi d'e-mail depuis `notifications@gong-galaxy.com`

**Pas de mot de passe ici.** Apps Script envoie via l'identité du compte qui exécute
(`MailApp` / `GmailApp`). Pour que l'expéditeur affiché soit `notifications@`, cette
adresse doit être configurée comme **alias « Envoyer en tant que » / délégation** côté
Google Workspace (tâche admin unique de FX). Voir `AGENTS.md` §8a.

## En cas de fuite

Si une clé se retrouve par erreur dans le code, un commit, un message ou un fichier :
préviens **FX immédiatement** — il faut la **révoquer et la régénérer**. Un secret
poussé dans Git reste dans l'historique et dans chaque clone : le supprimer ne suffit pas.
