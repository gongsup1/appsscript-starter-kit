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

ORG="gongsup1"                  # org GitHub
REF="main"                      # branche ou tag épinglé
REPO="appsscript-starter-kit"

say() { printf '\n\033[1;36m> %s\033[0m\n' "$1"; }

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

  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
    echo "" >&2
    echo "L'installation de Homebrew a echoue. Verifie ta connexion, puis relance la commande." >&2
    exit 1
  }

  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$b" ] && { eval "$("$b" shellenv)"; break; }
  done

  command -v brew >/dev/null 2>&1 || {
    echo "" >&2
    echo "Homebrew est installe mais pas encore visible dans ce Terminal." >&2
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
say "Quel assistant IA veux-tu utiliser ?"
select AI in "Claude Code" "Codex"; do [ -n "${AI:-}" ] && break; done

# --- 2. Node (requis pour clasp, quel que soit l'assistant) ---
if ! command -v node >/dev/null 2>&1; then
  ensure_brew
  say "Installation de Node..."
  brew install node
fi

# --- 3. L'assistant IA choisi ---
case "$AI" in
  "Claude Code")
    # App desktop GUI (onglet Code) = cask 'claude' -> Claude.app.
    # PAS 'claude-code', qui est le CLI terminal.
    if ! brew list --cask claude >/dev/null 2>&1; then
      ensure_brew
      say "Installation de l'app Claude (desktop)..."
      brew install --cask claude
    fi ;;
  "Codex")
    command -v codex >/dev/null 2>&1 || { say "Installation de Codex..."; npm install -g @openai/codex; } ;;
esac

# --- 4. Nom du projet + dossier de travail (~/coding-projects/<nom>) ---
read -rp "$(printf '\033[1;36m> Nom court du projet (ex. suivi-livraisons) : \033[0m')" NAME
NAME="$(printf '%s' "$NAME" | tr ' ' '-' | tr -cd '[:alnum:]-')"
[ -n "$NAME" ] || { echo "Nom vide — on arrete." >&2; exit 1; }
DIR="$HOME/coding-projects/$NAME"
[ -e "$DIR" ] && { echo "$DIR existe deja — choisis un autre nom, ou ouvre-le directement." >&2; exit 1; }
mkdir -p "$DIR"

# --- 5. Recuperer le squelette (repo public, sans historique Git) ---
say "Telechargement du squelette..."
curl -fsSL "https://github.com/$ORG/$REPO/archive/$REF.tar.gz" | tar -xz -C "$DIR" --strip-components=1
cd "$DIR"
rm -f bootstrap.sh   # l'installeur du template n'a rien a faire dans le repo du projet

# --- 6. Lancer l'assistant ---
PROMPT="Lis AGENTS.md et aide-moi a demarrer mon application (nom du projet : $NAME)."
case "$AI" in
  "Claude Code")
    # L'app desktop ne s'ouvre pas sur un dossier par script : on la lance, l'utilisateur
    # fait Code -> Select folder (quelques clics, zero terminal). Elle garde le dossier
    # en "recents" pour y revenir facilement ensuite.
    say "Ouverture de l'app Claude (desktop)..."
    open -a "Claude" 2>/dev/null || true
    printf '\033[1;36m'
    cat <<EOF

  ============================================================
   Ton projet est pret dans :
     $DIR

   Dans l'app Claude qui vient de s'ouvrir :
     1. Clique l'onglet   Code   (en haut).
     2. Clique   Select folder   et choisis le dossier ci-dessus.
     3. Ecris (ou colle) cette phrase, puis Entree :
        $PROMPT

   Pour REVENIR sur ce projet plus tard : ouvre l'app Claude,
   onglet Code -> il est dans tes dossiers recents.
  ============================================================
EOF
    printf '\033[0m\n' ;;
  "Codex")
    say "Pret dans $DIR — lancement de Codex."
    exec codex "$PROMPT" ;;
esac
