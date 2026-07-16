# Secrets du projet — `<NOM_DU_PROJET>`

> ⚠️ **Aucune valeur de secret ne va dans ce fichier ni nulle part dans le repo.**
> Ce fichier ne fait que **lister** les secrets à régler et **où trouver leur valeur**.

Les secrets se règlent dans les **Propriétés du script** — l'équivalent Apps Script d'un
`.env` : ils vivent **côté Google, jamais dans le dépôt**. Apps Script n'a **pas** de fichier
`.env` ni de variables d'environnement à l'exécution ; ces propriétés **ne se posent qu'à la
main dans l'éditeur** (ni `clasp`, ni l'API, ni l'IA ne peuvent les écrire — voir le pas-à-pas
ci-dessous). Les **valeurs** se récupèrent dans **1Password** (coffre `Vibe-coding`).

| Clé (= nom de la Propriété du script) | À quoi ça sert | Où trouver la valeur | Requis ? |
|---|---|---|---|
| `BREVO_API_KEY` | Envoi d'**e-mails** (§8a) **et de SMS** (§8b) via Brevo | 1Password → `Vibe-coding` → **la clé Brevo qui t'a été attribuée** (une clé **par utilisateur autorisé**, créée par le service informatique) | Oui si e-mail ou SMS |

## Régler `BREVO_API_KEY` — pas à pas (à faire une fois par app)

1. Ouvre l'éditeur du projet : l'IA lance `clasp open-script` (ou va sur
   <https://script.google.com> et ouvre le projet).
2. En bas à gauche, clique sur ⚙️ **Paramètres du projet**.
3. Descends jusqu'à **Propriétés du script**, puis clique **Ajouter une propriété de script**.
4. Champ **Propriété** (le nom, à taper **exactement**) : `BREVO_API_KEY`
5. Champ **Valeur** : ouvre **1Password** → coffre `Vibe-coding` → **la clé Brevo qui t'a été
   attribuée** (créée par le service informatique). Copie-la et **colle-la** ici. (Ne la tape
   pas à la main, ne la note nulle part.) Pas encore de clé ? Demande-la au service informatique.
6. Clique **Enregistrer les propriétés du script**. Terminé : l'app lira la clé toute seule
   via `PropertiesService`, sans que la valeur touche jamais le dépôt.

> La **première** fois que l'app appelle Brevo, Apps Script demande l'autorisation d'accès
> réseau (`UrlFetchApp`) : exécute `testEmail` (ou `sendSms_`) dans l'éditeur et **accepte**
> l'autorisation **avant** de redéployer (règle d'or n°9).

## Envoyer depuis `noreply@gong-galaxy.com`

`noreply@gong-galaxy.com` est un **compte Google Workspace à part entière**. L'envoi
passe par **Brevo** — **pas** par un alias Google : il suffit que cette adresse soit un
**expéditeur vérifié** dans Brevo et que le domaine `gong-galaxy.com` soit authentifié
(SPF/DKIM). C'est un réglage **côté Brevo/DNS**, fait une fois par un admin (voir `AGENTS.md`
§11). **Aucune** configuration d'alias « Envoyer en tant que » n'est nécessaire.

## En cas de fuite

Si une clé se retrouve par erreur dans le code, un commit, un message ou un fichier :
préviens **FX immédiatement** — il faut la **révoquer et la régénérer**. Un secret
poussé dans Git reste dans l'historique et dans chaque clone : le supprimer ne suffit pas.
