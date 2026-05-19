#!/usr/bin/env bash
# ============================================================
#  kali-terminal-setup.sh
#  Replica el terminal de Kali Linux en Ubuntu
#  Autor: FranVi  |  GitHub: Haplee
# ============================================================

set -e

# ── Colores para el output del script ──────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}[OK]${RESET}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error()   { echo -e "${RED}[ERR]${RESET}  $*"; exit 1; }

echo -e "${BOLD}"
echo "  ██╗  ██╗ █████╗ ██╗     ██╗    ████████╗███████╗██████╗ ███╗   ███╗"
echo "  ██║ ██╔╝██╔══██╗██║     ██║    ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║"
echo "  █████╔╝ ███████║██║     ██║       ██║   █████╗  ██████╔╝██╔████╔██║"
echo "  ██╔═██╗ ██╔══██║██║     ██║       ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║"
echo "  ██║  ██╗██║  ██║███████╗██║       ██║   ███████╗██║  ██║██║ ╚═╝ ██║"
echo "  ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝       ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝"
echo -e "${RESET}"
echo -e "  ${CYAN}Terminal idéntico a Kali Linux para Ubuntu${RESET}"
echo -e "  ${YELLOW}by FranVi${RESET}"
echo ""
echo "──────────────────────────────────────────────────────────────────"
echo ""

# ── Variables ──────────────────────────────────────────────
ZSHRC="$HOME/.zshrc"
TILIX_SCHEMES_DIR="$HOME/.config/tilix/schemes"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
USER_NAME=$(whoami)

# ============================================================
# PASO 1 — Dependencias del sistema
# ============================================================
info "Instalando dependencias del sistema..."
sudo apt update -qq
sudo apt install -y zsh curl git wget fonts-powerline dconf-cli uuid-runtime 2>/dev/null
success "Dependencias instaladas."

# ============================================================
# PASO 2 — Cambiar shell por defecto a zsh
# ============================================================
CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" != "zsh" ]; then
  info "Cambiando shell por defecto a zsh..."
  chsh -s "$(which zsh)" "$USER_NAME"
  success "Shell cambiado a zsh (efectivo al reiniciar sesión)."
else
  success "zsh ya es la shell por defecto."
fi

# ============================================================
# PASO 3 — Oh My Zsh
# ============================================================
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Instalando Oh My Zsh..."
  RUNZSH=no CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    "" --unattended
  success "Oh My Zsh instalado."
else
  success "Oh My Zsh ya está instalado."
fi

# ============================================================
# PASO 4 — Plugins: autosuggestions + syntax-highlighting
# ============================================================
info "Instalando plugins zsh..."

ZSH_AUTOSUGGEST_DIR="${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
ZSH_SYNTAX_DIR="${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"

if [ ! -d "$ZSH_AUTOSUGGEST_DIR" ]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGEST_DIR"
  success "zsh-autosuggestions instalado."
else
  success "zsh-autosuggestions ya existe."
fi

if [ ! -d "$ZSH_SYNTAX_DIR" ]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_SYNTAX_DIR"
  success "zsh-syntax-highlighting instalado."
else
  success "zsh-syntax-highlighting ya existe."
fi

# ============================================================
# PASO 5 — Hacer backup del .zshrc existente
# ============================================================
if [ -f "$ZSHRC" ]; then
  BACKUP="${ZSHRC}.backup.$(date +%Y%m%d_%H%M%S)"
  cp "$ZSHRC" "$BACKUP"
  info "Backup del .zshrc anterior → $BACKUP"
fi

# ============================================================
# PASO 6 — Escribir el nuevo .zshrc estilo Kali
# ============================================================
info "Escribiendo nuevo .zshrc..."

cat > "$ZSHRC" << 'EOF'
# ============================================================
#  ~/.zshrc — Kali Linux style | Ubuntu
#  Generado por kali-terminal-setup.sh
# ============================================================

export ZSH="$HOME/.oh-my-zsh"

# ── Oh My Zsh: tema base (lo sobreescribimos con PS1 manual) ──
ZSH_THEME=""

# ── Plugins ──────────────────────────────────────────────────
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  colored-man-pages
  command-not-found
)

source $ZSH/oh-my-zsh.sh

# ── Prompt exacto de Kali Linux ──────────────────────────────
autoload -U colors && colors

# Símbolo especial Kali
KALI_SYMBOL='㉿'

# Root → prompt rojo/azul | usuario normal → verde/azul
if [ "$EUID" -eq 0 ]; then
  PROMPT_COLOR_BORDER='%F{blue}'
  PROMPT_COLOR_USER='%F{red}'
  PROMPT_CHAR='#'
else
  PROMPT_COLOR_BORDER='%F{green}'
  PROMPT_COLOR_USER='%F{blue}'
  PROMPT_CHAR='$'
fi

PROMPT=$'${PROMPT_COLOR_BORDER}┌──(%B${PROMPT_COLOR_USER}%n'"${KALI_SYMBOL}"$'%m%b${PROMPT_COLOR_BORDER})-[%B%F{reset}%~%b${PROMPT_COLOR_BORDER}]\n└─%B${PROMPT_COLOR_USER}'"${PROMPT_CHAR}"$'%b%F{reset} '

# Prompt derecho: muestra código de error si el último comando falló
RPROMPT=$'%(?.. %F{red}✘ %?%F{reset})'

# ── Colores de zsh-autosuggestions ───────────────────────────
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#666666'

# ── Colores de zsh-syntax-highlighting (estilo Kali) ─────────
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=yellow,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=magenta,bold'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=white,underline'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[comment]='fg=gray'

# ── Historial ─────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# ── Aliases estilo Kali ───────────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias cls='clear'
alias update='sudo apt update && sudo apt upgrade -y'
alias please='sudo !!'

# ── Autocompletar ─────────────────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

EOF

success ".zshrc escrito."

# ============================================================
# PASO 7 — Paleta de colores Kali para Tilix
# ============================================================
info "Configurando paleta de colores Kali para Tilix..."

mkdir -p "$TILIX_SCHEMES_DIR"

cat > "$TILIX_SCHEMES_DIR/kali-dark.json" << 'EOF'
{
  "name": "Kali Dark",
  "comment": "Kali Linux default terminal colors",
  "use-theme-colors": false,
  "foreground-color": "#e0e0e0",
  "background-color": "#1c1c1c",
  "cursor-foreground-color": "#ffffff",
  "cursor-background-color": "#00ff00",
  "palette": [
    "#1c1c1c",
    "#ff4444",
    "#39ff14",
    "#ffcc00",
    "#1e90ff",
    "#cc44ff",
    "#00e5ff",
    "#e0e0e0",
    "#4a4a4a",
    "#ff6666",
    "#66ff66",
    "#ffdd55",
    "#66aaff",
    "#dd88ff",
    "#55eeff",
    "#ffffff"
  ]
}
EOF

success "Esquema kali-dark.json creado en $TILIX_SCHEMES_DIR"

# Aplicar esquema via dconf si Tilix está instalado
if command -v tilix &>/dev/null; then
  TILIX_PROFILE=$(dconf list /com/gexperts/Tilix/profiles/ 2>/dev/null | head -1 | tr -d '/')
  if [ -n "$TILIX_PROFILE" ]; then
    dconf write "/com/gexperts/Tilix/profiles/${TILIX_PROFILE}/foreground-color" "'#e0e0e0'"
    dconf write "/com/gexperts/Tilix/profiles/${TILIX_PROFILE}/background-color" "'#1c1c1c'"
    dconf write "/com/gexperts/Tilix/profiles/${TILIX_PROFILE}/use-theme-colors" "false"
    dconf write "/com/gexperts/Tilix/profiles/${TILIX_PROFILE}/palette" \
      "['#1c1c1c','#ff4444','#39ff14','#ffcc00','#1e90ff','#cc44ff','#00e5ff','#e0e0e0','#4a4a4a','#ff6666','#66ff66','#ffdd55','#66aaff','#dd88ff','#55eeff','#ffffff']"
    dconf write "/com/gexperts/Tilix/profiles/${TILIX_PROFILE}/cursor-background-color" "'#00ff00'"
    success "Paleta aplicada automáticamente a Tilix."
  else
    warn "No se encontró perfil de Tilix. Aplica manualmente el esquema desde Preferencias → Color."
  fi
else
  warn "Tilix no detectado. El esquema .json está guardado para importarlo manualmente."
fi

# ============================================================
# PASO 8 — Oh My Posh: desactivar si está activo
# ============================================================
if grep -q "oh-my-posh" "$ZSHRC" 2>/dev/null; then
  warn "Se detectó oh-my-posh en .zshrc — ya ha sido reemplazado por el prompt de Kali."
fi

# ============================================================
# RESUMEN FINAL
# ============================================================
echo ""
echo "──────────────────────────────────────────────────────────────────"
echo -e "${GREEN}${BOLD}  ✔ Setup completado${RESET}"
echo "──────────────────────────────────────────────────────────────────"
echo ""
echo -e "  ${CYAN}Prompt final:${RESET}"
echo -e "  ${GREEN}┌──(${RESET}${BOLD}${CYAN}${USER_NAME}㉿$(hostname)${RESET}${GREEN})-[~]${RESET}"
echo -e "  ${GREEN}└─${RESET}${BOLD}${CYAN}\$${RESET} _"
echo ""
echo -e "  ${YELLOW}Pasos para activar:${RESET}"
echo -e "  1. Reinicia la sesión  ${CYAN}→${RESET}  exec zsh"
echo -e "  2. O aplica ahora      ${CYAN}→${RESET}  source ~/.zshrc"
echo -e "  3. En Tilix: Preferencias → Perfil → Color → Esquema: Kali Dark"
echo ""
echo "──────────────────────────────────────────────────────────────────"