#!/usr/bin/env bash
# ============================================================
#  kali-terminal-setup.sh  v2.0.0
#  Replica el terminal de Kali Linux en Ubuntu/Debian
#  Autor: FranVi  |  GitHub: Haplee
# ============================================================

set -euo pipefail

# ── Colores ─────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}[ OK]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error()   { echo -e "${RED}[ERR]${RESET}  $*" >&2; exit 1; }
step()    { echo -e "\n${BOLD}${CYAN}━━━ $* ━━━${RESET}"; }

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
echo -e "  ${YELLOW}v2.0.0 — by FranVi (github.com/Haplee)${RESET}"
echo ""
echo "──────────────────────────────────────────────────────────────────"
echo ""

# ── Variables ────────────────────────────────────────────────
ZSHRC="$HOME/.zshrc"
TILIX_SCHEMES_DIR="$HOME/.config/tilix/schemes"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
USER_NAME="${USER:-$(whoami)}"
STEPS_OK=0
STEPS_WARN=0

# ── Registro de resultados ───────────────────────────────────
declare -a DONE_LIST=()
declare -a WARN_LIST=()

track_ok()   { DONE_LIST+=("$*"); (( STEPS_OK++ )); }
track_warn() { WARN_LIST+=("$*"); (( STEPS_WARN++ )); }

# ============================================================
# PASO 0 — Comprobaciones previas
# ============================================================
step "PASO 0 — Comprobaciones previas"

# Advertir si se ejecuta como root
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  warn "Estás ejecutando el script como root."
  warn "El .zshrc se instalará en /root y los plugins en /root/.oh-my-zsh."
  warn "Si quieres configurar un usuario normal, ejecútalo sin sudo."
  echo ""
fi

# Comprobar gestor de paquetes
if ! command -v apt &>/dev/null; then
  error "Este script requiere apt (Ubuntu/Debian). Adapta el PASO 1 a tu distro."
fi

# Comprobar conectividad antes de descargar nada
info "Comprobando conectividad..."
if ! curl -fsSL --max-time 5 https://raw.githubusercontent.com &>/dev/null; then
  error "Sin conexión a GitHub. Comprueba tu red e inténtalo de nuevo."
fi
success "Conectividad OK."
track_ok "Conectividad verificada"

# ============================================================
# PASO 1 — Dependencias del sistema
# ============================================================
step "PASO 1 — Dependencias del sistema"
info "Actualizando lista de paquetes..."
sudo apt-get update -qq

info "Instalando paquetes necesarios..."
sudo apt-get install -y \
  zsh curl git wget \
  fonts-powerline \
  dconf-cli uuid-runtime \
  command-not-found \
  2>/dev/null || warn "Algún paquete opcional no se pudo instalar."

success "Dependencias instaladas."
track_ok "Dependencias del sistema"

# ============================================================
# PASO 2 — Shell por defecto: zsh
# ============================================================
step "PASO 2 — Shell por defecto"
ZSH_BIN="$(command -v zsh)"
CURRENT_SHELL="$(basename "${SHELL:-bash}")"

if [ "$CURRENT_SHELL" != "zsh" ]; then
  info "Cambiando shell por defecto a zsh..."
  # usermod es más fiable en entornos automatizados que chsh
  if sudo usermod -s "$ZSH_BIN" "$USER_NAME" 2>/dev/null; then
    success "Shell cambiada a zsh (activa al reiniciar sesión)."
    track_ok "Shell cambiada a zsh"
  else
    # Fallback a chsh
    if chsh -s "$ZSH_BIN" "$USER_NAME" 2>/dev/null; then
      success "Shell cambiada a zsh mediante chsh."
      track_ok "Shell cambiada a zsh (chsh)"
    else
      warn "No se pudo cambiar la shell automáticamente. Ejecuta manualmente:"
      warn "  chsh -s $ZSH_BIN"
      track_warn "Shell no cambiada — cambiar manualmente con chsh"
    fi
  fi
else
  success "zsh ya es la shell por defecto."
  track_ok "zsh ya era la shell por defecto"
fi

# ============================================================
# PASO 3 — Oh My Zsh
# ============================================================
step "PASO 3 — Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Instalando Oh My Zsh (modo no interactivo)..."
  RUNZSH=no CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    "" --unattended
  success "Oh My Zsh instalado."
  track_ok "Oh My Zsh instalado"
else
  info "Actualizando Oh My Zsh..."
  git -C "$HOME/.oh-my-zsh" pull --quiet origin master 2>/dev/null \
    && success "Oh My Zsh actualizado." \
    || success "Oh My Zsh ya está en la última versión."
  track_ok "Oh My Zsh ya estaba instalado (verificado)"
fi

# ============================================================
# PASO 4 — Plugins zsh
# ============================================================
step "PASO 4 — Plugins zsh"

_clone_plugin() {
  local name="$1" url="$2" dir="$3"
  if [ ! -d "$dir" ]; then
    info "Clonando $name..."
    git clone --depth=1 "$url" "$dir"
    success "$name instalado."
    track_ok "Plugin: $name"
  else
    success "$name ya existe."
    track_ok "Plugin: $name (ya existía)"
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
# PASO 5 — Backup del .zshrc existente
# ============================================================
step "PASO 5 — Backup .zshrc"
BACKUP_CREATED=false
if [ -f "$ZSHRC" ]; then
  BACKUP="${ZSHRC}.backup.$(date +%Y%m%d_%H%M%S)"
  cp "$ZSHRC" "$BACKUP"
  success "Backup guardado → $BACKUP"
  track_ok "Backup: $BACKUP"
  BACKUP_CREATED=true
fi

# ============================================================
# PASO 6 — Nuevo .zshrc estilo Kali
# ============================================================
step "PASO 6 — Escribiendo .zshrc"
info "Generando configuración..."

cat > "$ZSHRC" << 'EOF'
# ============================================================
#  ~/.zshrc — Kali Linux style | Ubuntu/Debian
#  Generado por kali-terminal-setup.sh v2.0.0
#  https://github.com/Haplee/kali-terminal-setup
# ============================================================

export ZSH="$HOME/.oh-my-zsh"

# ── Oh My Zsh: sin tema (usamos prompt manual) ───────────────
ZSH_THEME=""

# ── Plugins ──────────────────────────────────────────────────
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  colored-man-pages
  command-not-found
)

# Cargar zsh-completions antes de OMZ
fpath+="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions/src"

source "$ZSH/oh-my-zsh.sh"

# ── Opciones de zsh ──────────────────────────────────────────
setopt AUTO_CD           # escribe un directorio para entrar
setopt CORRECT           # corrección de errores tipográficos
setopt GLOBDOTS          # incluye archivos ocultos en globbing
setopt EXTENDED_GLOB     # patrones glob avanzados
setopt NO_CASE_GLOB      # globbing case-insensitive

# ── Prompt exacto de Kali Linux ──────────────────────────────
autoload -U colors && colors

KALI_SYMBOL='㉿'

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  _PC_BORDER='%F{blue}'
  _PC_USER='%F{red}'
  _PCHAR='#'
else
  _PC_BORDER='%F{green}'
  _PC_USER='%F{blue}'
  _PCHAR='$'
fi

PROMPT=$'${_PC_BORDER}┌──(%B${_PC_USER}%n'"${KALI_SYMBOL}"$'%m%b${_PC_BORDER})-[%B%F{reset}%~%b${_PC_BORDER}]\n└─%B${_PC_USER}'"${_PCHAR}"$'%b%F{reset} '

# RPROMPT: código de error si el último comando falló
RPROMPT=$'%(?.. %F{red}✘ %?%F{reset})'

# ── zsh-autosuggestions ───────────────────────────────────────
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#666666'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ── zsh-syntax-highlighting (colores Kali) ────────────────────
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

# ── Historial ─────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS   # no guardar duplicados en absoluto
setopt HIST_IGNORE_SPACE      # no guardar si empieza con espacio
setopt HIST_FIND_NO_DUPS      # no mostrar duplicados en búsqueda
setopt HIST_REDUCE_BLANKS     # eliminar blancos extra
setopt SHARE_HISTORY          # compartir historial entre sesiones
setopt APPEND_HISTORY         # añadir al historial, no sobreescribir

# ── Autocompletar ─────────────────────────────────────────────
# Usar caché del dump para no regenerar en cada sesión
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*' rehash true
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always

# ── Aliases ───────────────────────────────────────────────────
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
alias ....='cd ../../..'
alias cls='clear'
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias search='apt search'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me && echo'
alias path='echo $PATH | tr ":" "\n"'

# Si bat está disponible, usarlo en lugar de cat
if command -v bat &>/dev/null; then
  alias cat='bat --style=plain --pager=never'
elif command -v batcat &>/dev/null; then
  alias cat='batcat --style=plain --pager=never'
fi

# Si eza/exa está disponible, potenciar ls
if command -v eza &>/dev/null; then
  alias ls='eza --color=auto --group-directories-first'
  alias ll='eza -lah --group-directories-first --git'
  alias la='eza -a --group-directories-first'
  alias tree='eza --tree'
elif command -v exa &>/dev/null; then
  alias ls='exa --color=auto --group-directories-first'
  alias ll='exa -lah --group-directories-first --git'
fi

# ── please: ejecutar el último comando con sudo ───────────────
# NOTA: 'sudo !!' no funciona en zsh — usamos una función
please() {
  local last_cmd
  last_cmd=$(fc -ln -1 | sed 's/^ *//')
  if [[ -n "$last_cmd" ]]; then
    eval "sudo $last_cmd"
  else
    echo "please: no hay ningún comando previo en el historial"
  fi
}

# ── Funciones útiles ─────────────────────────────────────────
# Crear directorio y entrar
mkcd() { mkdir -p "$1" && cd "$1"; }

# Extraer cualquier tipo de archivo comprimido
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1"   ;;
      *.tar.gz)  tar xzf "$1"   ;;
      *.tar.xz)  tar xJf "$1"   ;;
      *.tar.zst) tar --zstd -xf "$1" ;;
      *.bz2)     bunzip2 "$1"   ;;
      *.gz)      gunzip "$1"    ;;
      *.tar)     tar xf "$1"    ;;
      *.tbz2)    tar xjf "$1"   ;;
      *.tgz)     tar xzf "$1"   ;;
      *.zip)     unzip "$1"     ;;
      *.Z)       uncompress "$1";;
      *.7z)      7z x "$1"      ;;
      *.rar)     unrar x "$1"   ;;
      *)         echo "extract: formato no reconocido: $1" ;;
    esac
  else
    echo "extract: '$1' no es un archivo válido"
  fi
}

# Buscar en el historial
h() { history | grep --color=auto "$1"; }

# Mostrar IP local de cada interfaz activa
ips() {
  ip -brief addr | awk '$2 == "UP" {print $1, $3}'
}
EOF

success ".zshrc generado correctamente."
track_ok ".zshrc con prompt Kali, plugins, funciones y aliases"

# ============================================================
# PASO 7 — Paleta de colores Kali Dark para terminales
# ============================================================
step "PASO 7 — Paleta de colores"

# Paleta JSON (válida para Tilix y GNOME Terminal color schemes)
PALETTE_JSON='{"name":"Kali Dark","comment":"Kali Linux default terminal colors","use-theme-colors":false,"foreground-color":"#e0e0e0","background-color":"#1c1c1c","cursor-foreground-color":"#ffffff","cursor-background-color":"#00ff00","palette":["#1c1c1c","#ff4444","#39ff14","#ffcc00","#1e90ff","#cc44ff","#00e5ff","#e0e0e0","#4a4a4a","#ff6666","#66ff66","#ffdd55","#66aaff","#dd88ff","#55eeff","#ffffff"]}'

KALI_PALETTE="['#1c1c1c','#ff4444','#39ff14','#ffcc00','#1e90ff','#cc44ff','#00e5ff','#e0e0e0','#4a4a4a','#ff6666','#66ff66','#ffdd55','#66aaff','#dd88ff','#55eeff','#ffffff']"

# ── Tilix ────────────────────────────────────────────────────
mkdir -p "$TILIX_SCHEMES_DIR"
echo "$PALETTE_JSON" | python3 -m json.tool > "$TILIX_SCHEMES_DIR/kali-dark.json" 2>/dev/null \
  || echo "$PALETTE_JSON" > "$TILIX_SCHEMES_DIR/kali-dark.json"
success "Esquema kali-dark.json guardado en $TILIX_SCHEMES_DIR"

if command -v tilix &>/dev/null; then
  TILIX_PROFILE=$(dconf list /com/gexperts/Tilix/profiles/ 2>/dev/null | grep -oP '[0-9a-f-]+' | head -1)
  if [ -n "$TILIX_PROFILE" ]; then
    local TBASE="/com/gexperts/Tilix/profiles/${TILIX_PROFILE}"
    dconf write "${TBASE}/foreground-color"        "'#e0e0e0'"
    dconf write "${TBASE}/background-color"        "'#1c1c1c'"
    dconf write "${TBASE}/cursor-foreground-color" "'#ffffff'"
    dconf write "${TBASE}/cursor-background-color" "'#00ff00'"
    dconf write "${TBASE}/use-theme-colors"        "false"
    dconf write "${TBASE}/palette"                 "${KALI_PALETTE}"
    dconf write "${TBASE}/use-system-font"         "false"
    success "Paleta aplicada a Tilix (perfil: ${TILIX_PROFILE})."
    track_ok "Tilix: paleta Kali Dark aplicada"
  else
    warn "Tilix instalado pero sin perfil encontrado. Importa kali-dark.json desde Preferencias → Color."
    track_warn "Tilix: importar kali-dark.json manualmente"
  fi
else
  warn "Tilix no detectado. Esquema JSON disponible en: $TILIX_SCHEMES_DIR/kali-dark.json"
  track_warn "Tilix no instalado"
fi

# ── GNOME Terminal ────────────────────────────────────────────
if command -v gsettings &>/dev/null && gsettings list-schemas 2>/dev/null | grep -q "org.gnome.Terminal"; then
  GNOME_PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")
  if [ -n "$GNOME_PROFILE" ]; then
    GBASE="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${GNOME_PROFILE}/"
    gsettings set "$GBASE" foreground-color          '#e0e0e0'
    gsettings set "$GBASE" background-color          '#1c1c1c'
    gsettings set "$GBASE" use-theme-colors          false
    gsettings set "$GBASE" bold-is-bright            true
    gsettings set "$GBASE" palette \
      "['#1c1c1c','#ff4444','#39ff14','#ffcc00','#1e90ff','#cc44ff','#00e5ff','#e0e0e0','#4a4a4a','#ff6666','#66ff66','#ffdd55','#66aaff','#dd88ff','#55eeff','#ffffff']"
    success "Paleta aplicada a GNOME Terminal."
    track_ok "GNOME Terminal: paleta Kali Dark aplicada"
  fi
fi

# ============================================================
# PASO 8 — Detectar configuraciones conflictivas
# ============================================================
step "PASO 8 — Verificación de conflictos"

# Comprobar si oh-my-posh estaba en el backup
if [ "$BACKUP_CREATED" = true ] && grep -q "oh-my-posh" "$BACKUP" 2>/dev/null; then
  warn "Se detectó oh-my-posh en la configuración anterior — reemplazado por el prompt de Kali."
  warn "Backup disponible en: $BACKUP"
  track_warn "oh-my-posh detectado en backup — reemplazado"
fi

# Comprobar si starship estaba activo
if [ "$BACKUP_CREATED" = true ] && grep -q "starship" "$BACKUP" 2>/dev/null; then
  warn "Se detectó starship en la configuración anterior — reemplazado."
  track_warn "starship detectado en backup — reemplazado"
fi

success "Verificación completada."

# ============================================================
# RESUMEN FINAL
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}${BOLD}  ✔ Setup completado — ${STEPS_OK} pasos OK  /  ${STEPS_WARN} advertencias${RESET}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Listar lo hecho
echo -e "  ${GREEN}Completado:${RESET}"
for item in "${DONE_LIST[@]}"; do
  echo -e "    ${GREEN}✓${RESET} $item"
done

# Listar advertencias si las hay
if [ ${#WARN_LIST[@]} -gt 0 ]; then
  echo ""
  echo -e "  ${YELLOW}Advertencias:${RESET}"
  for item in "${WARN_LIST[@]}"; do
    echo -e "    ${YELLOW}⚠${RESET} $item"
  done
fi

echo ""
echo -e "  ${CYAN}Prompt instalado:${RESET}"
echo -e "  ${GREEN}┌──(${RESET}${BOLD}${CYAN}${USER_NAME}㉿$(hostname)${RESET}${GREEN})-[~]${RESET}"
echo -e "  ${GREEN}└─${RESET}${BOLD}${CYAN}\$${RESET} _"
echo ""
echo -e "  ${YELLOW}Para activar ahora:${RESET}"
echo -e "    ${CYAN}exec zsh${RESET}          — recarga la shell en esta sesión"
echo -e "    ${CYAN}source ~/.zshrc${RESET}   — recarga solo la config"
if command -v tilix &>/dev/null; then
  echo -e "    En Tilix: Preferencias → Perfil → Color → ${BOLD}Kali Dark${RESET}"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"