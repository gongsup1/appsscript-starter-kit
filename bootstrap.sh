#!/usr/bin/env bash
#
# GONG : démarrage d'une app Google Apps Script depuis le template.
#
# À lancer en UNE commande (copier-coller dans le Terminal), forme « à la Homebrew » :
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/gongsup1/appsscript-starter-kit/main/bootstrap.sh)"
#
# Cette forme garde le clavier disponible pour les questions (contrairement à "curl ... | bash").
# ORG et REF sont deja renseignes ci-dessous (org: gongsup1, ref: main).

set -euo pipefail

# Mode NON-interactif pour Homebrew : sans ca, comme le script garde un vrai terminal
# (pour les questions), brew se croit interactif et demande "Do you want to proceed? [y/n]".
# Ces variables le font enchainer sans confirmation, et evitent un auto-update long au milieu.
# (Le mot de passe Mac de 'sudo -v' reste demande : sudo n'est pas concerne par ces variables.)
export NONINTERACTIVE=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1

# Journal des commandes longues : on y redirige les details (brew, etc.) pour garder
# l'ecran propre. En cas d'echec, run_quiet affiche la fin de ce log.
LOG="$(mktemp -t gong-bootstrap)"

ORG="gongsup1"                  # org GitHub
REF="main"                      # branche ou tag épinglé
REPO="appsscript-starter-kit"

say() { printf '\n\033[1;36m> %s\033[0m\n' "$1"; }

# --- Barre de progression : rassure quand une etape prend du temps ---
# On affiche "Etape N/6" + une barre visuelle a chaque grande etape. Les etapes
# sont fixes (meme si Node/Homebrew/l'app sont deja installes, l'etape est juste rapide),
# pour que la progression reste previsible.
STEP=0
TOTAL_STEPS=6
progress() {
  STEP=$((STEP + 1))
  local label="$1" width=20 i bar="" filled empty pct
  filled=$(( STEP * width / TOTAL_STEPS ))
  empty=$(( width - filled ))
  for ((i = 0; i < filled; i++)); do bar="${bar}#"; done
  for ((i = 0; i < empty;  i++)); do bar="${bar}-"; done
  pct=$(( STEP * 100 / TOTAL_STEPS ))
  printf '\n\033[1;36m[%s] %3d%%   Etape %d/%d : %s\033[0m\n' "$bar" "$pct" "$STEP" "$TOTAL_STEPS" "$label"
}

# Lance une commande longue SANS afficher ses details (rediriges dans $LOG), avec un petit
# indicateur qui tourne pour montrer que ca avance. Sur succes : "OK". Sur echec : affiche la
# fin du log (pour diagnostiquer) et arrete le script.
#   Usage : run_quiet "Message a l'ecran" commande arg1 arg2...
run_quiet() {
  local msg="$1"; shift
  printf '\033[0;36m   %s \033[0m' "$msg"
  ( "$@" ) >>"$LOG" 2>&1 </dev/null &
  local pid=$! i=0 c spin='|/-\'
  while kill -0 "$pid" 2>/dev/null; do
    c=$(( i % 4 )); i=$(( i + 1 ))
    printf '\b%s' "${spin:c:1}"
    sleep 0.2
  done
  if wait "$pid"; then
    printf '\b\033[0;32mOK\033[0m\n'
  else
    local rc=$?
    printf '\b\033[1;31mECHEC\033[0m\n' >&2
    printf '\033[1;31m   Details (dernieres lignes) :\033[0m\n' >&2
    tail -n 20 "$LOG" >&2
    printf '\033[1;31m   -> Corrige le probleme ci-dessus (souvent : reseau), puis relance la meme commande.\033[0m\n' >&2
    printf '   Log complet : %s\n' "$LOG" >&2
    exit "$rc"
  fi
}

# Rend un Homebrew deja present utilisable : dans CE script, ET durablement pour les nouveaux
# terminaux et l'app Claude. Sur Mac Apple Silicon, Homebrew vit dans /opt/homebrew, hors du
# PATH par defaut ; son installeur AFFICHE la ligne a ajouter au profil mais ne l'ajoute pas.
# Sans elle, node / npm / clasp / gh sont "introuvables" des qu'on sort de ce script.
# On l'ecrit dans DEUX fichiers : ~/.zprofile (recommandation Homebrew, lu par le Terminal) et
# ~/.zshrc (le fichier que la doc Claude desktop cite pour recuperer le PATH).
# Retourne 1 si Homebrew n'est pas installe.
load_brew() {
  local b profile line
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$b" ] || continue
    eval "$("$b" shellenv)"
    line="eval \"\$($b shellenv)\""
    case "$(basename "${SHELL:-zsh}")" in
      bash) set -- "$HOME/.bash_profile" "$HOME/.bashrc" ;;
      *)    set -- "$HOME/.zprofile" "$HOME/.zshrc" ;;
    esac
    for profile in "$@"; do
      grep -qsF "$line" "$profile" ||
        printf '\n# Homebrew (ajoute par le bootstrap GONG)\n%s\n' "$line" >>"$profile"
    done
    return 0
  done
  return 1
}

# Vrai si "npm install -g" peut ecrire SANS sudo. C'est le cas avec le Node de Homebrew ou de
# nvm ; pas avec celui de l'installeur officiel (.pkg), qui renvoie EACCES. Or l'IA installe
# clasp avec "npm install -g" et ne peut pas taper de mot de passe admin.
npm_global_ok() {
  local p
  p="$(npm prefix -g 2>/dev/null)" || return 1
  [ -w "$p/bin" ] && [ -w "$p/lib/node_modules" ]
}

# Installe Homebrew si absent (base pour Node, l'app Claude, gh).
# Le tout premier install de Homebrew a besoin des droits admin (mot de passe Mac).
# On pre-autorise sudo AVANT de lancer l'installeur : sinon, en mode non-interactif,
# Homebrew teste "sudo -n" (sans jamais demander le mot de passe), le test echoue et
# l'installeur s'arrete sur "Need sudo access on macOS" (meme pour un vrai admin).
KEEPALIVE_PID=""
ensure_brew() {
  if command -v brew >/dev/null 2>&1; then
    # Homebrew installe par un AUTRE compte du Mac : visible, mais pas modifiable par celui-ci.
    if [ ! -w "$(brew --prefix)/Cellar" ]; then
      echo "" >&2
      echo "Homebrew est installe sur ce Mac par un autre compte utilisateur :" >&2
      echo "ce compte-ci ne peut pas s'en servir pour installer des outils." >&2
      echo "-> Lance ce bootstrap depuis le compte qui a installe Homebrew, ou demande a FX." >&2
      exit 1
    fi
    return 0
  fi

  say "Installation de Homebrew (l'outil qui pose Node et l'app)."
  cat <<'EOF'
  macOS va te demander TON mot de passe Mac (celui de ta session).
  C'est normal et attendu : c'est pour installer Homebrew.

  IMPORTANT : le mot de passe se tape A L'AVEUGLE dans le Terminal.
  Rien ne s'affiche pendant la frappe (ni points, ni etoiles, et le curseur ne bouge pas).
  C'est voulu (securite). Tape ton mot de passe normalement, puis Entree.
  (Sur certains Mac, c'est Touch ID a la place du mot de passe.)

EOF

  # Pre-autorise sudo. Si l'utilisateur n'est pas administrateur, ceci echoue proprement.
  if ! sudo -v; then
    echo "" >&2
    echo "Impossible d'obtenir les droits administrateur (sudo)." >&2
    echo "Homebrew ne peut pas s'installer sans un compte admin du Mac." >&2
    echo "-> Lance ce bootstrap depuis un compte administrateur, ou demande a l'IT / a FX." >&2
    exit 1
  fi

  # Le ticket sudo expire au bout de 5 min, et le telechargement des outils Xcode par Homebrew
  # peut durer plus longtemps : on le renouvelle en tache de fond pendant l'installation.
  # En cas d'arret du script, le trap coupe cette boucle et referme les droits admin.
  ( while kill -0 "$$" 2>/dev/null; do sudo -n -v 2>/dev/null; sleep 30; done ) \
    </dev/null >/dev/null 2>&1 &
  KEEPALIVE_PID=$!
  trap 'kill "$KEEPALIVE_PID" 2>/dev/null; sudo -k' EXIT

  run_quiet "Installation de Homebrew (2 a 5 min, jusqu'a 15 min sur un Mac neuf)" \
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Installation finie : on referme les droits admin. Rien de ce qui suit (ni l'assistant IA
  # lance a la fin) n'en a besoin.
  kill "$KEEPALIVE_PID" 2>/dev/null || true
  sudo -k
  trap - EXIT

  load_brew || {
    echo "" >&2
    echo "Homebrew n'a pas pu s'installer (reseau ou droits ?)." >&2
    echo "-> Ferme puis rouvre le Terminal et relance la meme commande." >&2
    exit 1
  }
}

# --- Garde-fou : il faut un vrai terminal pour les questions ---
if [ ! -t 0 ]; then
  echo 'Lance : /bin/bash -c "$(curl -fsSL <URL>)" (et non "curl ... | bash").' >&2
  exit 1
fi

# Homebrew deja installe mais absent du PATH (profil jamais configure) : on le rebranche, pour
# que les tests ci-dessous voient le Node qu'il a pu installer.
command -v brew >/dev/null 2>&1 || load_brew || true

# --- 1. Quel assistant IA ? ---
progress "Choix de l'assistant IA"
say "Quel assistant IA veux-tu utiliser ?"
select AI in "Claude Code" "Codex"; do [ -n "${AI:-}" ] && break; done
# Ctrl+D au menu : select sort de la boucle sans choix.
[ -n "${AI:-}" ] || { echo "Aucun assistant choisi : on arrete." >&2; exit 1; }

# --- 2. Node (requis pour clasp, quel que soit l'assistant) ---
progress "Verification de Node"
if command -v node >/dev/null 2>&1 && npm_global_ok; then
  say "Node est deja installe."
else
  # Node absent, ou installe d'une facon qui empeche "npm install -g" sans mot de passe :
  # on pose celui de Homebrew, qui passe devant dans le PATH.
  ensure_brew
  run_quiet "Installation de Node (~1 a 2 min)" brew install node
  hash -r
  npm_global_ok || {
    echo "" >&2
    echo "Node est installe, mais 'npm install -g' demande encore des droits admin." >&2
    echo "-> Demande a FX (un Node installe a la main entre sans doute en conflit)." >&2
    exit 1
  }
fi

# --- 3. L'assistant IA choisi ---
progress "Installation de l'assistant ($AI)"
case "$AI" in
  "Claude Code")
    # App desktop GUI (onglet Code) = cask 'claude' -> Claude.app.
    # PAS 'claude-code', qui est le CLI terminal.
    # On teste la presence de l'app elle-meme, pas "brew list" : si elle a ete telechargee
    # depuis claude.ai, brew ne la connait pas et refuserait de l'installer par-dessus.
    if [ -d "/Applications/Claude.app" ] || [ -d "$HOME/Applications/Claude.app" ]; then
      say "L'app Claude est deja installee."
    else
      ensure_brew
      run_quiet "Installation de l'app Claude (~quelques min)" brew install --cask claude
    fi ;;
  "Codex")
    if command -v codex >/dev/null 2>&1; then
      say "Codex est deja installe."
    else
      run_quiet "Installation de Codex (~1 min)" npm install -g @openai/codex
    fi ;;
esac

# --- 4. Nom du projet + dossier de travail (~/coding-projects/<nom>) ---
progress "Nom du projet et dossier de travail"
read -rp "$(printf '\033[1;36m> Nom court du projet (ex. suivi-livraisons) : \033[0m')" NAME
# Nom normalise en minuscules ASCII ("Équipe Livraisons" -> "equipe-livraisons") : il sert de
# nom de dossier, de repo GitHub, et son chemin sera colle dans la fenetre de choix de dossier.
NAME="$(printf '%s' "$NAME" \
  | LC_ALL=en_US.UTF-8 sed 'y/àâäéèêëîïôöùûüÿçÀÂÄÉÈÊËÎÏÔÖÙÛÜŸÇ/aaaeeeeiioouuuycAAAEEEEIIOOUUUYC/' \
  | tr ' _' '--' | LC_ALL=C tr -cd 'A-Za-z0-9-' | tr 'A-Z' 'a-z' \
  | sed 's/--*/-/g; s/^-//; s/-$//')"
[ -n "$NAME" ] || { echo "Nom vide : on arrete." >&2; exit 1; }
DIR="$HOME/coding-projects/$NAME"
[ -e "$DIR" ] && { echo "$DIR existe deja : choisis un autre nom, ou ouvre-le directement." >&2; exit 1; }
mkdir -p "$DIR"

# --- 5. Recuperer le squelette (repo public, sans historique Git) ---
progress "Telechargement du squelette"
# En cas d'echec, on supprime le dossier a moitie cree : sinon la relance bute sur "existe deja".
if ! curl -fsSL "https://github.com/$ORG/$REPO/archive/$REF.tar.gz" | tar -xz -C "$DIR" --strip-components=1; then
  rm -rf "$DIR"
  echo "" >&2
  echo "Telechargement du squelette impossible (reseau ?)." >&2
  echo "-> Verifie la connexion, puis relance la meme commande." >&2
  exit 1
fi
cd "$DIR"
rm -f bootstrap.sh   # l'installeur du template n'a rien a faire dans le repo du projet

# --- 6. Lancer l'assistant ---
progress "Lancement de l'assistant"
# La phrase porte le chemin attendu : si le mauvais dossier a ete ouvert (parent, sous-dossier
# design-system/...), l'IA s'en apercoit et fait rouvrir le bon au lieu de travailler au mauvais
# endroit. Sans accents : pbcopy peut abimer les caracteres accentues selon la langue du Mac.
PROMPT="Lis AGENTS.md et aide-moi a demarrer mon application (projet : $NAME, dossier : $DIR). Verifie d'abord que tu travailles bien dans ce dossier."
case "$AI" in
  "Claude Code")
    # Lien de l'app Claude desktop qui ouvre une NOUVELLE session Code directement DANS le
    # dossier du projet, avec la phrase de demarrage deja ecrite. C'est le lien qu'utilise l'app
    # elle-meme pour son action Finder "New Claude Code Session Here" (claude://code/new?folder=).
    # Il n'est pas documente publiquement : on garde un plan B manuel a l'ecran.
    # Encodage pour URL fait comme l'app (encodeURIComponent via osascript, fourni par macOS).
    urlencode() {
      V="$1" osascript -l JavaScript \
        -e 'ObjC.import("stdlib"); function run(){return encodeURIComponent($.getenv("V"))}'
    }
    DEEPLINK="claude://code/new?folder=$(urlencode "$DIR")&q=$(urlencode "$PROMPT")"
    # Pour le plan B : la phrase reste disponible dans le presse-papier.
    printf '%s' "$PROMPT" | pbcopy 2>/dev/null || true

    say "Ouverture de ton projet dans l'app Claude..."
    open "$DEEPLINK" 2>/dev/null || open -a "Claude" 2>/dev/null || true
    printf '\033[1;36m'
    cat <<EOF

  ============================================================
   Ton projet est pret dans :
     $DIR

   Claude s'ouvre sur ton projet (onglet Code), avec la phrase
   de demarrage deja ecrite. Dans Claude :
     - s'il demande de faire confiance a ce dossier : reponds oui ;
     - puis appuie sur   Entree   pour lancer l'assistant.
   >>> Claude NE demarre PAS tout seul : c'est cette phrase,
       envoyee avec Entree, qui le met au travail.

   Premiere utilisation de Claude ? Il te demande d'abord de te
   connecter. Une fois connecte, si ton projet n'est pas affiche,
   reviens ici et appuie sur Entree : on le rouvre.

   Plan B, si ca ne marche toujours pas : dans Claude, onglet Code,
   Select folder, choisis le dossier ci-dessus, puis colle la
   phrase (Cmd + V, elle est deja copiee) et Entree.

   Pour REVENIR sur ce projet plus tard : ouvre l'app Claude,
   onglet Code, il est dans tes dossiers recents.
  ============================================================
EOF
    printf '\033[0m'
    read -rp $'\n\033[1;36m> Entree = rouvrir ton projet dans Claude. Si tout est bon, ferme simplement cette fenetre. \033[0m' _
    open "$DEEPLINK" 2>/dev/null || true
    printf '\n' ;;
  "Codex")
    say "Pret dans $DIR, lancement de Codex."
    exec codex "$PROMPT" ;;
esac
