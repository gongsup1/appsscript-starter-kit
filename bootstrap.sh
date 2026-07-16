#!/usr/bin/env bash
#
# GONG — démarrage d'une app Google Apps Script depuis le template.
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

# Installe Homebrew si absent (base pour Node, l'app Claude, gh).
# Le tout premier install de Homebrew a besoin des droits admin (mot de passe Mac).
# On pre-autorise sudo AVANT de lancer l'installeur : sinon, en mode non-interactif,
# Homebrew teste "sudo -n" (sans jamais demander le mot de passe), le test echoue et
# l'installeur s'arrete sur "Need sudo access on macOS" -- meme pour un vrai admin.
ensure_brew() {
  command -v brew >/dev/null 2>&1 && return 0

  say "Installation de Homebrew (l'outil qui pose Node et l'app)."
  cat <<'EOF'
  macOS va te demander TON mot de passe Mac (celui de ta session).
  C'est normal et attendu : c'est pour installer Homebrew.

  IMPORTANT : le mot de passe se tape A L'AVEUGLE dans le Terminal.
  Rien ne s'affiche pendant la frappe -- ni points, ni etoiles, et le curseur ne bouge pas.
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

  run_quiet "Installation de Homebrew (2 a 5 min)" \
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$b" ] && { eval "$("$b" shellenv)"; break; }
  done

  command -v brew >/dev/null 2>&1 || {
    echo "" >&2
    echo "Homebrew n'a pas pu s'installer (reseau ou droits ?)." >&2
    echo "-> Ferme puis rouvre le Terminal et relance la meme commande." >&2
    exit 1
  }
}

# --- Garde-fou : il faut un vrai terminal pour les questions ---
if [ ! -t 0 ]; then
  echo 'Lance : /bin/bash -c "$(curl -fsSL <URL>)"   — et non "curl ... | bash".' >&2
  exit 1
fi

# --- 1. Quel assistant IA ? ---
progress "Choix de l'assistant IA"
say "Quel assistant IA veux-tu utiliser ?"
select AI in "Claude Code" "Codex"; do [ -n "${AI:-}" ] && break; done

# --- 2. Node (requis pour clasp, quel que soit l'assistant) ---
progress "Verification de Node"
if ! command -v node >/dev/null 2>&1; then
  ensure_brew
  run_quiet "Installation de Node (~1 a 2 min)" brew install node
else
  say "Node est deja installe."
fi

# --- 3. L'assistant IA choisi ---
progress "Installation de l'assistant ($AI)"
case "$AI" in
  "Claude Code")
    # App desktop GUI (onglet Code) = cask 'claude' -> Claude.app.
    # PAS 'claude-code', qui est le CLI terminal.
    if ! brew list --cask claude >/dev/null 2>&1; then
      ensure_brew
      run_quiet "Installation de l'app Claude (~quelques min)" brew install --cask claude
    else
      say "L'app Claude est deja installee."
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
NAME="$(printf '%s' "$NAME" | tr ' ' '-' | tr -cd '[:alnum:]-')"
[ -n "$NAME" ] || { echo "Nom vide — on arrete." >&2; exit 1; }
DIR="$HOME/coding-projects/$NAME"
[ -e "$DIR" ] && { echo "$DIR existe deja — choisis un autre nom, ou ouvre-le directement." >&2; exit 1; }
mkdir -p "$DIR"

# --- 5. Recuperer le squelette (repo public, sans historique Git) ---
progress "Telechargement du squelette"
curl -fsSL "https://github.com/$ORG/$REPO/archive/$REF.tar.gz" | tar -xz -C "$DIR" --strip-components=1
cd "$DIR"
rm -f bootstrap.sh   # l'installeur du template n'a rien a faire dans le repo du projet

# --- 6. Lancer l'assistant ---
progress "Lancement de l'assistant"
PROMPT="Lis AGENTS.md et aide-moi a demarrer mon application (nom du projet : $NAME)."
case "$AI" in
  "Claude Code")
    # L'app desktop ne s'ouvre pas sur un dossier par script : on la lance, l'utilisateur
    # fait Code -> Select folder (quelques clics, zero terminal). Elle garde le dossier
    # en "recents" pour y revenir facilement ensuite.
    say "Ouverture de l'app Claude (desktop)..."
    open -a "Claude" 2>/dev/null || true
    # Copie la phrase dans le presse-papier : l'utilisateur n'a plus qu'a coller (Cmd+V).
    printf '%s' "$PROMPT" | pbcopy 2>/dev/null || true
    printf '\033[1;36m'
    cat <<EOF

  ============================================================
   Ton projet est pret dans :
     $DIR

   >>> IMPORTANT : Claude NE demarre PAS tout seul. <<<
   Ouvrir le dossier ne lance rien : c'est la PHRASE ci-dessous,
   envoyee avec Entree, qui met l'assistant au travail.

   Dans l'app Claude qui vient de s'ouvrir :
     1. Clique l'onglet   Code   (en haut).
     2. Clique   Select folder   et choisis le dossier ci-dessus.
     3. Clique dans la zone de saisie, COLLE la phrase avec Cmd+V
        (elle est deja copiee), puis appuie sur Entree :

        "$PROMPT"

   -> Tant que tu n'as pas envoye cette phrase, il ne se passe rien : c'est normal.

   Pour REVENIR sur ce projet plus tard : ouvre l'app Claude,
   onglet Code -> il est dans tes dossiers recents.
  ============================================================
EOF
    printf '\033[0m\n' ;;
  "Codex")
    say "Pret dans $DIR — lancement de Codex."
    exec codex "$PROMPT" ;;
esac
