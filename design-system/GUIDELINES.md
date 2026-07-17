# Système de design — Outils internes GONG

Base visuelle partagée par les web-apps internes (Apps Script). Objectif : des outils
qui se ressemblent, **sobres**, lisibles, et cohérents d'une app à l'autre — sans effort
de design à chaque projet.

**Fichiers**
| Fichier | Rôle |
|---|---|
| `brand.css` | Tous les tokens (`--gg-*`) + les composants génériques. **La seule feuille à charger.** |
| `header.js` | En-tête partagé `<app-header>` (logo · nom d'app · utilisateur connecté). |
| `showcase.html` | Vitrine : le florilège de tous les composants (à ouvrir dans un navigateur). |

Pour voir le rendu : ouvrez **`showcase.html`** dans un navigateur.

---

## 1. Principes

1. **Sobre avant tout.** Niveaux de gris, le **noir** (`--gg-accent`) est le *seul* accent
   structurel (boutons principaux, états actifs). Pas de couleur dans le châssis.
2. **La couleur = feedback uniquement.** Info / succès / alerte / erreur, et seulement dans
   les alertes, statuts et validations de formulaire. Jamais en décoration.
3. **Gris doux, pas blanc pur.** Le fond est un gris clair reposant (`--gg-bg`), les cartes
   légèrement plus claires. Moins de fatigue visuelle sur écran.
4. **Un seul thème pour l'instant** (clair). Pas de sélecteur clair/sombre — on garde simple.
   Un thème sombre pourra être réintroduit plus tard (tout passe par les tokens).
5. **Responsive par défaut.** Desktop, tablette, mobile. Contenu large (tableaux) qui défile
   dans son conteneur, jamais toute la page.
6. **Accessible.** Focus visible, contrastes tenus, cibles tactiles ≥ 34 px, `prefers-reduced-motion` respecté.

> **Pas de vert.** Le vert de marque (`#aaff00`) a été retiré : trop agressif sur cette UI sobre.

---

## 2. Tokens (`--gg-*`)

Toujours passer par les variables, jamais de valeur en dur.

**Surfaces** `--gg-bg` (page) · `--gg-surface` (cartes) · `--gg-surface-2` (blocs en creux, code) · `--gg-surface-3`
**Lignes** `--gg-border` · `--gg-border-strong` (actif / focus, ~noir)
**Texte** `--gg-text` · `--gg-text-muted`
**Accent** `--gg-accent` / `--gg-accent-hover` / `--gg-on-accent`
**Feedback** `--gg-{error,success,warning,info}` + variantes `-soft` (fond) et `-border`
**Forme** `--gg-radius` (8 px) · `--gg-radius-pill` (boutons) · `--gg-shadow` / `--gg-shadow-hover`
**Type** `--gg-font` (Helvetica d'abord) · `--gg-mono`

---

## 3. Typographie

Échelle : `h1` 1.7rem/700 · `h2` 1.15rem/600 · `h3` 1rem/600 · `h4` 0.9rem/600 ·
corps 1rem/1.5 · `.lead` 1.05rem atténué · `.small` 0.85rem · `.eyebrow`/`.label`
0.74rem capitales espacées. Titres en `letter-spacing:-0.02em` + `text-wrap:balance`.
Largeur de lecture confortable ~65–70 caractères (conteneur ≤ 720 px).

## 4. Espacement & layout

Rythme par multiples de ~4 px (gaps 8/12/16/22). Utilitaires : `.container` (largeur max
centrée), `.stack` (rythme vertical), `.row` / `.cluster` (flex + wrap + gap). **Espacer via
le layout (`gap`), pas des marges élément par élément.**

---

## 5. Composants (voir `showcase.html`)

- **Boutons** `.btn` + `.primary` (noir) · `.ghost` · `.subtle` · `.danger` · `.small` · `.icon` · `.block`. Pilule, un seul bouton *primary* par zone d'action.
- **Badges / statuts / chips** `.badge`(`.solid`) · `.status`(`.ok/.warn/.err/.info/.idle`) · `.chip` (avec × pour retirer).
- **Alertes** `.alert` + `.info/.success/.warning/.error/.neutral`, avec icône + titre + corps.
- **Formulaires** `.field` (label + `input`/`textarea`/`select` + `.help`), `.field.invalid` pour l'erreur, `.check` (case + description), `.switch` (interrupteur).
- **Cartes & indicateurs** `.card`, `.stats`/`.stat`, `.icon-badge`.
- **Tableau** `.table-wrap` (défilement) + `table.data`, colonnes numériques `.num`.
- **Onglets** `.tabs`/`.tab` (`aria-selected`).
- **Progression / chargement** `.progress`, `.spinner`, `.skeleton`.
- **Infobulle** `.tip[data-tip]`. **Dépôt** `.dropzone`.
- **Overlays** `.modal-overlay`/`.modal` (pop-up) et `.toast` dans `.toast-region`.

---

## 6. En-tête (`<app-header>`)

Ordre imposé : **logo à gauche → barre verticale → nom de l'application**, puis, poussé à
droite, **l'utilisateur connecté** (toujours affiché).

```html
<link rel="stylesheet" href="brand.css" />
<script src="header.js" defer></script>
<app-header app-name="Suivi livraisons"
            user-name="Jean Dupont"
            user-email="jean.dupont@gong-galaxy.com"></app-header>
```

**Afficher l'utilisateur Google Workspace (dans une web-app Apps Script).** Le backend
injecte l'utilisateur courant du domaine dans le template `doGet` :

```js
function doGet() {
  const tpl = HtmlService.createTemplateFromFile('Index');
  const email = Session.getActiveUser().getEmail();   // e-mail de la personne connectée (même domaine)
  tpl.userEmail = email;
  tpl.userName  = email;   // ou un nom d'affichage plus lisible
  return tpl.evaluate();
}
```
```html
<app-header app-name="…" user-name="<?= userName ?>" user-email="<?= userEmail ?>"></app-header>
```

> `Session.getActiveUser().getEmail()` renvoie l'e-mail quand l'utilisateur est dans le même
> domaine que le script (`access: DOMAIN`, notre cas). Sinon, le header affiche « Non connecté ».
> On peut aussi le définir en JS : `document.querySelector('app-header').setUser({name, email})`.

Responsive : sous 560 px le header ne garde que l'avatar (le nom/e-mail passe en `title`).

---

## 7. Responsive

Mobile-first dans l'usage : tout se replie proprement. `<meta name="viewport">` obligatoire.
Images `max-width:100%`. Tableaux et onglets défilent horizontalement dans leur conteneur.
Sur mobile, la pop-up devient une feuille en bas d'écran et les toasts s'étirent en largeur.

## 8. À faire / à éviter

**À faire** : passer par les tokens ; un seul *primary* par écran ; couleur = feedback ;
tester à 360 px de large ; garder le focus visible.
**À éviter** : couleurs en dur ; empiler les boutons noirs ; colorer pour décorer ;
réintroduire le vert ; du texte sur fond blanc pur.
