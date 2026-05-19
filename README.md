# kali-terminal-setup

> Replica el terminal de **Kali Linux** en Ubuntu/Debian y Windows — prompt idéntico, colores, plugins y paleta Kali Dark. Un solo script, sin configuración manual.

[![Bash](https://img.shields.io/badge/bash-v2.1.0-89e051?style=flat-square&logo=gnubash)](kali-terminal-setup.sh)
[![PowerShell](https://img.shields.io/badge/PowerShell-v1.1.0-5391FE?style=flat-square&logo=powershell)](kali-setup-windows.ps1)
[![Ubuntu](https://img.shields.io/badge/Ubuntu%2FDebian-compatible-E95420?style=flat-square&logo=ubuntu)](https://ubuntu.com)
[![Windows](https://img.shields.io/badge/Windows%2010%2F11-compatible-0078D4?style=flat-square&logo=windows)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-Haplee-181717?style=flat-square&logo=github)](https://github.com/Haplee)

---

## Resultado final

```
┌──(franvi㉿kali)-[~/proyectos]
└─$ _
```

- Prompt de **dos líneas** idéntico al de Kali Linux
- Usuario normal → borde **verde**, nombre en **azul**
- Root → borde **azul**, nombre en **rojo** con `#`
- `RPROMPT` / lado derecho muestra `✘ <código>` si el último comando falló
- Integración con **git**: rama, cambios sin commitear y commits por delante/detrás

---

## Requisitos

### Linux
| Requisito | Detalle |
|-----------|---------|
| Distro | Ubuntu 20.04+ / Debian 11+ |
| Permisos | `sudo` disponible |
| Red | Acceso a GitHub (descarga OMZ y plugins) |

### Windows
| Requisito | Detalle |
|-----------|---------|
| OS | Windows 10 21H2+ / Windows 11 |
| Shell | PowerShell 5.1+ |
| Gestor paquetes | `winget` (incluido en Win11; en Win10 instalar *App Installer* desde Store) |
| Terminal | [Windows Terminal](https://aka.ms/terminal) |
| Red | Acceso a internet |

---

## Instalación

### Linux (Ubuntu / Debian)

```bash
git clone https://github.com/Haplee/kali-terminal-setup.git
cd kali-terminal-setup
chmod +x kali-terminal-setup.sh
./kali-terminal-setup.sh
```

Activar en la sesión actual:

```bash
exec zsh          # cambia a zsh en esta sesión
source ~/.zshrc   # o recarga solo la configuración
```

En **Tilix**: `Preferencias → Perfil → Color → Esquema: Kali Dark`  
En **GNOME Terminal**: la paleta se aplica automáticamente vía `gsettings`

---

### Windows (nativo)

```powershell
git clone https://github.com/Haplee/kali-terminal-setup.git
cd kali-terminal-setup

# Solo si la política de ejecución lo requiere:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

.\kali-setup-windows.ps1
```

Activar en la sesión actual:

```powershell
. $PROFILE   # recarga el perfil de PowerShell
```

En **Windows Terminal**: `Configuración → Perfil → Apariencia → Esquema de colores: Kali Dark`

---

### WSL2

El script Linux funciona **tal cual** dentro de WSL2 (Ubuntu):

```powershell
wsl --install -d Ubuntu   # primera vez (requiere reinicio)
```

```bash
# Dentro de WSL2:
./kali-terminal-setup.sh
```

---

## ¿Qué instala cada script?

### `kali-terminal-setup.sh` — Linux

| Paso | Acción |
|------|--------|
| 0 | Comprobaciones: root, `apt`, conectividad |
| 1 | Instala dependencias: `zsh`, `curl`, `git`, `fonts-powerline`, `dconf-cli`, `command-not-found` |
| 2 | Cambia la shell por defecto a zsh (`usermod` → `chsh` como fallback) |
| 3 | Instala / actualiza **Oh My Zsh** en modo no interactivo |
| 4 | Clona plugins: `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions` |
| 5 | Backup del `.zshrc` existente con timestamp |
| 6 | Escribe `.zshrc` completo con prompt Kali, plugins, aliases y funciones |
| 7 | Crea paleta **Kali Dark** y la aplica en Tilix (dconf) y GNOME Terminal (gsettings) |
| 8 | Detecta conflictos: oh-my-posh, starship en el backup |

### `kali-setup-windows.ps1` — Windows

| Paso | Acción |
|------|--------|
| 0 | Comprobaciones: PowerShell, winget, conectividad, ExecutionPolicy |
| 1 | Instala / actualiza **Oh My Posh** vía winget |
| 2 | Instala **FiraCode Nerd Font** vía `oh-my-posh font install` |
| 3 | Instala / verifica **PSReadLine** >= 2.2.0 |
| 4 | Genera tema `kali.omp.json` con prompt de dos líneas idéntico a Kali |
| 5 | Backup del perfil de PowerShell + escribe nuevo perfil con todos los aliases |
| 6 | Inyecta esquema **Kali Dark** en `settings.json` de Windows Terminal (con backup) |

---

## Características del `.zshrc` generado

### Plugins
| Plugin | Función |
|--------|---------|
| `zsh-autosuggestions` | Sugerencias en gris basadas en historial + completado |
| `zsh-syntax-highlighting` | Resaltado en tiempo real (verde=válido, rojo=desconocido) |
| `zsh-completions` | Completado extendido con 600+ comandos adicionales |
| `git` | Aliases y utilidades de git integradas |
| `colored-man-pages` | `man` con colores |
| `command-not-found` | Sugiere el paquete apt cuando el comando no existe |

### Aliases
| Alias | Acción |
|-------|--------|
| `ll` | `ls -lah --color=auto` |
| `la` | `ls -A --color=auto` |
| `update` | `sudo apt update && sudo apt upgrade -y` |
| `install` | `sudo apt install` |
| `search` | `apt search` |
| `ports` | `ss -tulnp` |
| `myip` | IP pública vía `ifconfig.me` |
| `..` / `...` / `....` | Navegar directorios padre |
| `cls` | `clear` |

### Funciones
| Función | Uso |
|---------|-----|
| `please` | Repite el último comando con `sudo` (funciona en zsh) |
| `mkcd <dir>` | Crea el directorio y entra en él |
| `extract <archivo>` | Extrae `.zip`, `.tar.gz`, `.tar.xz`, `.7z`, `.rar`, `.bz2`... |
| `h <patrón>` | Busca en el historial de comandos |
| `ips` | Muestra las IPs de interfaces de red activas |

### Historial
- **50.000 entradas**, `HIST_IGNORE_ALL_DUPS`, `HIST_FIND_NO_DUPS`, `APPEND_HISTORY`
- Compartido entre sesiones con `SHARE_HISTORY`

### Herramientas modernas (si están instaladas)
- `bat` / `batcat` → sustituye a `cat` automáticamente
- `eza` / `exa` → sustituye a `ls` y `ll` automáticamente

---

## Características del perfil PowerShell generado

### PSReadLine
- **Predicción** de historial con vista en lista (↑↓ para navegar)
- **Colores Kali**: comandos en verde neón, strings en amarillo, errores en rojo
- `Tab` → menú de completado
- `→` → acepta sugerencia completa
- Historial de 50.000 entradas con guardado incremental

### Aliases equivalentes
`ll`, `la`, `..`, `...`, `cls`, `update`, `please`, `myip`, `ports`, `ips`, `mkcd`, `extract`, `h`

---

## Paleta Kali Dark

El archivo `schemes/kali-dark.json` es compatible con Tilix, GNOME Terminal y Windows Terminal.

| # | Nombre | Hex | # | Nombre | Hex |
|---|--------|-----|---|--------|-----|
| 0 | Black | `#1c1c1c` | 8 | Bright Black | `#4a4a4a` |
| 1 | Red | `#ff4444` | 9 | Bright Red | `#ff6666` |
| 2 | Green | `#39ff14` | 10 | Bright Green | `#66ff66` |
| 3 | Yellow | `#ffcc00` | 11 | Bright Yellow | `#ffdd55` |
| 4 | Blue | `#1e90ff` | 12 | Bright Blue | `#66aaff` |
| 5 | Magenta | `#cc44ff` | 13 | Bright Magenta | `#dd88ff` |
| 6 | Cyan | `#00e5ff` | 14 | Bright Cyan | `#55eeff` |
| 7 | White | `#e0e0e0` | 15 | Bright White | `#ffffff` |

**Fondo**: `#1c1c1c` · **Texto**: `#e0e0e0` · **Cursor**: `#00ff00`

---

## Robustez y seguridad

Ambos scripts están diseñados para **no abortar ante fallos no críticos**:

- ✅ Cada paso es independiente — un fallo no cancela los siguientes
- ✅ Backup automático de `.zshrc` y `settings.json` con timestamp
- ✅ Verificación de conectividad antes de descargar nada
- ✅ Detección automática de conflictos (oh-my-posh, starship)
- ✅ Resumen final con columnas OK / WARN / FAIL
- ✅ PowerShell: JSONC stripping antes de parsear `settings.json`
- ✅ PowerShell: 3 rutas alternativas para detectar Windows Terminal
- ✅ PowerShell: corrección automática de `ExecutionPolicy`

---

## Compatibilidad

| Plataforma | Terminal | Script | Estado |
|------------|----------|--------|--------|
| Ubuntu 20.04+ / Debian 11+ | Tilix | `kali-terminal-setup.sh` | ✅ Paleta automática vía dconf |
| Ubuntu 20.04+ / Debian 11+ | GNOME Terminal | `kali-terminal-setup.sh` | ✅ Paleta automática vía gsettings |
| Cualquier distro apt | Kitty / Alacritty | — | ⚠️ Adapta colores manualmente |
| Windows 10/11 | Windows Terminal | `kali-setup-windows.ps1` | ✅ Paleta + prompt Oh My Posh |
| Windows 10/11 | WSL2 (Ubuntu) | `kali-terminal-setup.sh` | ✅ Funciona completo |

---

## Estructura del repositorio

```
kali-terminal-setup/
├── kali-terminal-setup.sh      # Script Linux — bash v2.1.0
├── kali-setup-windows.ps1      # Script Windows — PowerShell v1.1.0
├── schemes/
│   └── kali-dark.json          # Paleta Kali Dark (standalone, importable)
├── docs/
│   ├── index.html              # Demo interactiva (GitHub Pages)
│   ├── favicon.png             # Favicon dragón Kali
│   └── preview.md              # Descripción visual del resultado
├── .gitignore
├── LICENSE                     # MIT
└── README.md
```

---

## Demo interactiva

La web del proyecto incluye un terminal interactivo donde puedes probar el prompt, el resaltado de sintaxis y las autosugerencias sin instalar nada:

🌐 **[haplee.github.io/kali-terminal-setup](https://haplee.github.io/kali-terminal-setup)**

*(Activa GitHub Pages en Settings → Pages → Branch: `main` → Folder: `/docs`)*

---

## Contribuciones

PR e issues bienvenidos.

- Si usas una distro sin `apt`, abre un issue con los cambios necesarios para tu gestor de paquetes
- Si encuentras un terminal compatible no listado, PR con el script de configuración

---

## Autor

**FranVi** · Técnico Superior ASIR

[![GitHub](https://img.shields.io/badge/GitHub-Haplee-181717?style=flat-square&logo=github)](https://github.com/Haplee)
[![Instagram](https://img.shields.io/badge/Instagram-franvidalmateo-E4405F?style=flat-square&logo=instagram)](https://www.instagram.com/franvidalmateo)
[![X](https://img.shields.io/badge/X-FranVidalMateo-000000?style=flat-square&logo=x)](https://x.com/FranVidalMateo)

---

## Licencia

[MIT](LICENSE) — úsalo, modifícalo y compártelo libremente.
