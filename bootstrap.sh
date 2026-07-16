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

ORG="gongsup1"                     # org GitHub (ex. gong-galaxy)
REF="main"                      # branche ou tag épinglé (ex. v1)
REPO="appsscript-starter-kit"

say() { printf '\n\033[1;36m> %s\033[0m\n' "$1"; }

# URL-encode (pur bash, sans dependance a python) — pour le deep-link de l'app desktop.
urlencode() {
  local s="$1" out='' c i
  for (( i = 0; i < ${#s}; i++ )); do
    c="${s:i:1}"
    case "$c" in
      [a-zA-Z0-9.~_-]) out+="$c" ;;
      *) printf -v c '%%%02X' "'$c"; out+="$c" ;;
    esac
  done
  printf '%s' "$out"
}

# Installe Homebrew si absent (base pour Node, l'app Claude Code, gh).
ensure_brew() {
  command -v brew >/dev/null 2>&1 && return
  say "Installation de Homebrew (mot de passe Mac probablement demande)..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$b" ] && { eval "$("$b" shellenv)"; break; }
  done
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
    # App desktop (GUI) plutot que le CLI npm : plus accueillant pour un non-dev.
    if ! brew list --cask claude-code >/dev/null 2>&1; then
      ensure_brew
      say "Installation de l'app Claude Code (desktop)..."
      brew install --cask claude-code
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

# --- 6. Lancer l'assistant (il posera ensuite les vraies questions) ---
PROMPT="Lis AGENTS.md et aide-moi a demarrer mon application (nom du projet : $NAME)."
case "$AI" in
  "Claude Code")
    # Deep-link : ouvre l'app desktop DANS le dossier, avec la phrase de depart pre-remplie
    # (l'utilisateur n'a qu'a appuyer sur Entree — le prompt n'est jamais auto-envoye).
    say "Ouverture de l'app Claude Code sur ton projet..."
    if open "claude-cli://open?cwd=$DIR&q=$(urlencode "$PROMPT")"; then
      say "C'est pret : dans la fenetre Claude Code, la phrase de depart est deja ecrite — appuie sur Entree pour lancer."
    else
      say "Ouverture auto impossible. Ouvre l'app Claude Code, choisis 'Open folder' -> $DIR, puis tape : $PROMPT"
    fi ;;
  "Codex")
    say "Pret dans $DIR — lancement de Codex."
    exec codex "$PROMPT" ;;
esac
