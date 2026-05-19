#!/usr/bin/env bash
# ============================================================
#  kali-terminal-setup.sh  v2.1.0
#  Replica el terminal de Kali Linux en Ubuntu/Debian
#  Autor: FranVi  |  GitHub: Haplee
# ============================================================

# pipefail: un pipe fallido propaga el error, pero NO usamos set -e
# para que los pasos no críticos no aborten el script
set -uo pipefail

# ── Colores ─────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}[ OK]${RESET}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
err_msg() { echo -e "${RED}[ERR]${RESET}  $*" >&2; }
step()    { echo -e "\n${BOLD}${CYAN}━━━ $* ━━━${RESET}"; }

# ── Tracking ─────────────────────────────────────────────────
DONE_LIST=(); WARN_LIST=(); FAIL_LIST=()
track_ok()   { DONE_LIST+=("$*"); }
track_warn() { WARN_LIST+=("$*"); }
track_fail() { FAIL_LIST+=("$*"); }

# ── Trap para errores inesperados ────────────────────────────
trap 'err_msg "Error inesperado en línea $LINENO. Revisa la salida anterior."; exit 1' ERR

# ── Banner ───────────────────────────────────────────────────
echo -e "${BOLD}${GREEN}"
cat << 'BANNER'
  ██╗  ██╗ █████╗ ██╗     ██╗    ████████╗███████╗██████╗ ███╗   ███╗
  ██║ ██╔╝██╔══██╗██║     ██║    ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║
  █████╔╝ ███████║██║     ██║       ██║   █████╗  ██████╔╝██╔████╔██║
  ██╔═██╗ ██╔══██║██║     ██║       ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║
  ██║  ██╗██║  ██║███████╗██║       ██║   ███████╗██║  ██║██║ ╚═╝ ██║
  ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝       ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝
BANNER
echo -e "${RESET}"
echo -e "  ${CYAN}Terminal idéntico a Kali Linux para Ubuntu/Debian${RESET}"
echo -e "  ${YELLOW}v2.1.0 — by FranVi (github.com/Haplee)${RESET}\n"
echo "──────────────────────────────────────────────────────────────────"

# ── Variables ────────────────────────────────────────────────
ZSHRC="$HOME/.zshrc"
TILIX_SCHEMES_DIR="$HOME/.config/tilix/schemes"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
USER_NAME="${USER:-$(whoami)}"
BACKUP_PATH=""

# ============================================================
# PASO 0 — Comprobaciones previas
# ============================================================
step "PASO 0 — Comprobaciones previas"

# Desactivar trap durante comprobaciones no fatales
trap - ERR

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  warn "Ejecutando como root. El .zshrc se instalará en /root."
  warn "Para un usuario normal, ejecútalo sin sudo."
  track_warn "Ejecutado como root"
fi

if ! command -v apt &>/dev/null; then
  err_msg "apt no encontrado — este script requiere Ubuntu/Debian."
  exit 1
fi

info "Comprobando conectividad con GitHub..."
if curl -fsSL --max-time 8 https://raw.githubusercontent.com -o /dev/null 2>/dev/null; then
  success "Conectividad OK."
  track_ok "Conectividad verificada"
else
  err_msg "Sin acceso a GitHub. Comprueba tu red."
  exit 1
fi

# Reactivar trap
trap 'err_msg "Error inesperado en línea $LINENO"; exit 1' ERR

# ============================================================
# PASO 1 — Dependencias del sistema
# ============================================================
step "PASO 1 — Dependencias del sistema"

info "Actualizando lista de paquetes..."
if sudo apt-get update -qq; then
  success "apt update OK."
else
  warn "apt update falló — continuando con el caché existente."
  track_warn "apt update no completado"
fi

PKGS=(zsh curl git wget fonts-powerline dconf-cli uuid-runtime command-not-found)
FAILED_PKGS=()

info "Instalando paquetes: ${PKGS[*]}"
for pkg in "${PKGS[@]}"; do
  if sudo apt-get install -y "$pkg" &>/dev/null; then
    success "  $pkg"
  else
    warn "  $pkg no se pudo instalar"
    FAILED_PKGS+=("$pkg")
  fi
done

if [ ${#FAILED_PKGS[@]} -eq 0 ]; then
  track_ok "Dependencias del sistema instaladas"
else
  track_warn "Paquetes no instalados: ${FAILED_PKGS[*]}"
fi

# ============================================================
# PASO 2 — Shell por defecto: zsh
# ============================================================
step "PASO 2 — Shell por defecto"

ZSH_BIN="$(command -v zsh 2>/dev/null || true)"
if [ -z "$ZSH_BIN" ]; then
  err_msg "zsh no está instalado y no se pudo instalar en el paso anterior."
  exit 1
fi

CURRENT_SHELL="$(basename "${SHELL:-bash}")"
if [ "$CURRENT_SHELL" = "zsh" ]; then
  success "zsh ya es la shell por defecto."
  track_ok "zsh ya era la shell por defecto"
else
  info "Cambiando shell a zsh..."
  CHANGED=false
  if sudo usermod -s "$ZSH_BIN" "$USER_NAME" 2>/dev/null; then
    CHANGED=true
  elif chsh -s "$ZSH_BIN" "$USER_NAME" 2>/dev/null; then
    CHANGED=true
  fi

  if $CHANGED; then
    success "Shell cambiada a zsh (efectiva al reiniciar sesión)."
    track_ok "Shell cambiada a zsh"
  else
    warn "No se pudo cambiar la shell automáticamente."
    warn "Ejecuta manualmente: chsh -s $ZSH_BIN"
    track_warn "Shell no cambiada — ejecuta: chsh -s $ZSH_BIN"
  fi
fi

# ============================================================
# PASO 3 — Oh My Zsh
# ============================================================
step "PASO 3 — Oh My Zsh"

# Desactivar trap durante la instalación de OMZ (usa set -e internamente)
trap - ERR

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Instalando Oh My Zsh..."
  if RUNZSH=no CHSH=no \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
      "" --unattended 2>&1 | tail -5; then
    success "Oh My Zsh instalado."
    track_ok "Oh My Zsh instalado"
  else
    err_msg "Oh My Zsh no se pudo instalar."
    track_fail "Oh My Zsh — fallo crítico"
    exit 1
  fi
else
  info "Actualizando Oh My Zsh..."
  if git -C "$HOME/.oh-my-zsh" pull --quiet --rebase origin master 2>/dev/null; then
    success "Oh My Zsh actualizado."
  else
    warn "No se pudo actualizar Oh My Zsh (puede que no haya red o ya esté al día)."
  fi
  track_ok "Oh My Zsh ya instalado"
fi

trap 'err_msg "Error inesperado en línea $LINENO"; exit 1' ERR

# ============================================================
# PASO 4 — Plugins zsh
# ============================================================
step "PASO 4 — Plugins zsh"

_clone_plugin() {
  local name="$1" url="$2" dir="$3"
  if [ -d "$dir" ]; then
    success "$name ya existe."
    track_ok "Plugin: $name (ya existía)"
    return 0
  fi
  info "Clonando $name..."
  if git clone --depth=1 "$url" "$dir" 2>&1 | tail -1; then
    success "$name instalado."
    track_ok "Plugin: $name"
  else
    warn "No se pudo clonar $name."
    track_warn "Plugin: $name — fallo al clonar"
  fi
}

_clone_plugin "zsh-autosuggestions" \
  "https://github.com/zsh-users/zsh-autosuggestions" \
  "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"

_clone_plugin "zsh-syntax-highlighting" \
  "https://github.com/zsh-users/zsh-syntax-highlighting" \
  "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"

_clone_plugin "zsh-completions" \
  "https://github.com/zsh-users/zsh-completions" \
  "${ZSH_CUSTOM}/plugins/zsh-completions"

# ============================================================
# PASO 5 — Backup .zshrc
# ============================================================
step "PASO 5 — Backup .zshrc"

if [ -f "$ZSHRC" ]; then
  BACKUP_PATH="${ZSHRC}.backup.$(date +%Y%m%d_%H%M%S)"
  if cp "$ZSHRC" "$BACKUP_PATH"; then
    success "Backup guardado → $BACKUP_PATH"
    track_ok "Backup: $BACKUP_PATH"
  else
    warn "No se pudo crear backup de .zshrc"
    track_warn "Backup de .zshrc fallido"
  fi
else
  info "No existe .zshrc previo — no se requiere backup."
fi

# ============================================================
# PASO 6 — Escribir .zshrc
# ============================================================
step "PASO 6 — Escribiendo .zshrc"

cat > "$ZSHRC" << 'EOF'
# ============================================================
#  ~/.zshrc — Kali Linux style | Ubuntu/Debian
#  Generado por kali-terminal-setup.sh v2.1.0
#  https://github.com/Haplee/kali-terminal-setup
# ============================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  colored-man-pages
  command-not-found
)

fpath+="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions/src"
source "$ZSH/oh-my-zsh.sh"

# ── Opciones ────────────────────────────────────────────────
setopt AUTO_CD CORRECT GLOBDOTS EXTENDED_GLOB NO_CASE_GLOB

# ── Prompt Kali ──────────────────────────────────────────────
autoload -U colors && colors
KALI_SYMBOL='㉿'
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  _PC_BORDER='%F{blue}'; _PC_USER='%F{red}'; _PCHAR='#'
else
  _PC_BORDER='%F{green}'; _PC_USER='%F{blue}'; _PCHAR='$'
fi
PROMPT=$'${_PC_BORDER}┌──(%B${_PC_USER}%n'"${KALI_SYMBOL}"$'%m%b${_PC_BORDER})-[%B%F{reset}%~%b${_PC_BORDER}]\n└─%B${_PC_USER}'"${_PCHAR}"$'%b%F{reset} '
RPROMPT=$'%(?.. %F{red}✘ %?%F{reset})'

# ── Autosugerencias ─────────────────────────────────────────
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#666666'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ── Syntax highlighting ──────────────────────────────────────
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
ZSH_HIGHLIGHT_STYLES[globbing]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=magenta'

# ── Historial ────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000; SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS SHARE_HISTORY APPEND_HISTORY

# ── Completado ───────────────────────────────────────────────
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then compinit; else compinit -C; fi
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*' rehash true

# ── Aliases ──────────────────────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cls='clear'
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias search='apt search'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me && echo'

command -v bat    &>/dev/null && alias cat='bat --style=plain --pager=never'
command -v batcat &>/dev/null && alias cat='batcat --style=plain --pager=never'
command -v eza    &>/dev/null && { alias ls='eza --color=auto --group-directories-first'; alias ll='eza -lah --git'; }
command -v exa    &>/dev/null && { alias ls='exa --color=auto'; alias ll='exa -lah --git'; }

# ── please: último comando con sudo ─────────────────────────
please() {
  local last_cmd
  last_cmd=$(fc -ln -1 2>/dev/null | sed 's/^ *//')
  if [[ -n "$last_cmd" ]]; then
    eval "sudo $last_cmd"
  else
    echo "please: no hay comando previo en el historial"
    return 1
  fi
}

# ── Funciones ────────────────────────────────────────────────
mkcd()   { mkdir -p "$1" && cd "$1"; }

extract() {
  [[ -f "$1" ]] || { echo "extract: '$1' no es un archivo"; return 1; }
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz)         tar xJf "$1" ;;
    *.tar.zst)        tar --zstd -xf "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.gz)             gunzip  "$1" ;;
    *.tar)            tar xf  "$1" ;;
    *.zip)            unzip   "$1" ;;
    *.Z)              uncompress "$1" ;;
    *.7z)             7z x    "$1" ;;
    *.rar)            unrar x "$1" ;;
    *)  echo "extract: formato no reconocido: $1"; return 1 ;;
  esac
}

h()   { history | grep --color=auto "$1"; }
ips() { ip -brief addr | awk '$2 == "UP" {print $1, $3}'; }
EOF

success ".zshrc escrito correctamente."
track_ok ".zshrc con prompt Kali, plugins, funciones y aliases"

# ============================================================
# PASO 7 — Paleta de colores
# ============================================================
step "PASO 7 — Paleta de colores"

KALI_PALETTE="['#1c1c1c','#ff4444','#39ff14','#ffcc00','#1e90ff','#cc44ff','#00e5ff','#e0e0e0','#4a4a4a','#ff6666','#66ff66','#ffdd55','#66aaff','#dd88ff','#55eeff','#ffffff']"

# Crear directorio y esquema JSON
mkdir -p "$TILIX_SCHEMES_DIR"
cat > "$TILIX_SCHEMES_DIR/kali-dark.json" << 'EOFJ'
{
  "name": "Kali Dark",
  "comment": "Kali Linux default terminal colors",
  "use-theme-colors": false,
  "foreground-color": "#e0e0e0",
  "background-color": "#1c1c1c",
  "cursor-foreground-color": "#ffffff",
  "cursor-background-color": "#00ff00",
  "palette": [
    "#1c1c1c","#ff4444","#39ff14","#ffcc00","#1e90ff","#cc44ff","#00e5ff","#e0e0e0",
    "#4a4a4a","#ff6666","#66ff66","#ffdd55","#66aaff","#dd88ff","#55eeff","#ffffff"
  ]
}
EOFJ
success "kali-dark.json guardado en $TILIX_SCHEMES_DIR"

# ── Tilix ────────────────────────────────────────────────────
if command -v tilix &>/dev/null; then
  # Extraer UUID del perfil con grep+sed (más portable que PCRE)
  TILIX_PROFILE=$(dconf list /com/gexperts/Tilix/profiles/ 2>/dev/null \
    | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' \
    | head -1 || true)

  if [ -n "$TILIX_PROFILE" ]; then
    TBASE="/com/gexperts/Tilix/profiles/${TILIX_PROFILE}"
    dconf write "${TBASE}/foreground-color"        "'#e0e0e0'" 2>/dev/null || true
    dconf write "${TBASE}/background-color"        "'#1c1c1c'" 2>/dev/null || true
    dconf write "${TBASE}/cursor-background-color" "'#00ff00'" 2>/dev/null || true
    dconf write "${TBASE}/use-theme-colors"        "false"     2>/dev/null || true
    dconf write "${TBASE}/palette"                 "${KALI_PALETTE}" 2>/dev/null || true
    success "Paleta Kali Dark aplicada en Tilix."
    track_ok "Tilix: paleta Kali Dark aplicada"
  else
    warn "Tilix instalado pero sin perfil dconf. Importa kali-dark.json manualmente."
    track_warn "Tilix: importar kali-dark.json desde Preferencias → Color"
  fi
else
  warn "Tilix no detectado. Esquema en: $TILIX_SCHEMES_DIR/kali-dark.json"
  track_warn "Tilix no instalado"
fi

# ── GNOME Terminal ────────────────────────────────────────────
if command -v gsettings &>/dev/null; then
  GNOME_PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null \
    | tr -d "'" || true)
  if [ -n "$GNOME_PROFILE" ]; then
    GBASE="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${GNOME_PROFILE}/"
    gsettings set "$GBASE" foreground-color  '#e0e0e0' 2>/dev/null || true
    gsettings set "$GBASE" background-color  '#1c1c1c' 2>/dev/null || true
    gsettings set "$GBASE" use-theme-colors  false      2>/dev/null || true
    gsettings set "$GBASE" bold-is-bright    true       2>/dev/null || true
    gsettings set "$GBASE" palette \
      "['#1c1c1c','#ff4444','#39ff14','#ffcc00','#1e90ff','#cc44ff','#00e5ff','#e0e0e0','#4a4a4a','#ff6666','#66ff66','#ffdd55','#66aaff','#dd88ff','#55eeff','#ffffff']" \
      2>/dev/null || true
    success "Paleta Kali Dark aplicada en GNOME Terminal."
    track_ok "GNOME Terminal: paleta aplicada"
  fi
fi

# ============================================================
# PASO 8 — Verificación de conflictos
# ============================================================
step "PASO 8 — Verificación"

if [ -n "$BACKUP_PATH" ] && [ -f "$BACKUP_PATH" ]; then
  grep -q "oh-my-posh" "$BACKUP_PATH" 2>/dev/null && \
    { warn "oh-my-posh detectado en backup — reemplazado."; track_warn "oh-my-posh estaba activo"; }
  grep -q "starship"   "$BACKUP_PATH" 2>/dev/null && \
    { warn "starship detectado en backup — reemplazado."; track_warn "starship estaba activo"; }
fi

success "Verificación completada."

# ============================================================
# RESUMEN FINAL
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ ${#FAIL_LIST[@]} -eq 0 ]; then
  echo -e "${GREEN}${BOLD}  ✔ Setup completado — ${#DONE_LIST[@]} OK · ${#WARN_LIST[@]} advertencias${RESET}"
else
  echo -e "${YELLOW}${BOLD}  ⚠ Setup con fallos — ${#DONE_LIST[@]} OK · ${#WARN_LIST[@]} avisos · ${#FAIL_LIST[@]} fallos${RESET}"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[ ${#DONE_LIST[@]} -gt 0 ] && { echo -e "\n  ${GREEN}Completado:${RESET}"; for i in "${DONE_LIST[@]}"; do echo -e "    ${GREEN}✓${RESET} $i"; done; }
[ ${#WARN_LIST[@]} -gt 0 ] && { echo -e "\n  ${YELLOW}Advertencias:${RESET}"; for i in "${WARN_LIST[@]}"; do echo -e "    ${YELLOW}⚠${RESET} $i"; done; }
[ ${#FAIL_LIST[@]} -gt 0 ] && { echo -e "\n  ${RED}Fallos:${RESET}"; for i in "${FAIL_LIST[@]}"; do echo -e "    ${RED}✗${RESET} $i"; done; }

echo -e "\n  ${CYAN}Prompt instalado:${RESET}"
echo -e "  ${GREEN}┌──(${RESET}${BOLD}${CYAN}${USER_NAME}㉿$(hostname)${RESET}${GREEN})-[~]${RESET}"
echo -e "  ${GREEN}└─${RESET}${BOLD}${CYAN}\$${RESET} _"
echo -e "\n  ${YELLOW}Para activar:${RESET}"
echo -e "    ${CYAN}exec zsh${RESET}       — recarga la shell en esta sesión"
echo -e "    ${CYAN}source ~/.zshrc${RESET} — recarga solo la configuración"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"