# kali-terminal-setup

> Replica el terminal de Kali Linux en **Ubuntu/Debian** y **Windows** — prompt idéntico, colores, plugins y paleta Kali Dark.

![Bash](https://img.shields.io/badge/shell-bash-89e051?style=flat-square&logo=gnubash)
![PowerShell](https://img.shields.io/badge/shell-PowerShell-5391FE?style=flat-square&logo=powershell)
![Ubuntu](https://img.shields.io/badge/platform-Ubuntu%2FDebian-E95420?style=flat-square&logo=ubuntu)
![Windows](https://img.shields.io/badge/platform-Windows-0078D4?style=flat-square&logo=windows)
![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)
![Author](https://img.shields.io/badge/author-FranVi-informational?style=flat-square)

---

## ¿Qué hace?

| Paso | Acción |
|------|--------|
| 1 | Instala dependencias del sistema (`zsh`, `git`, `curl`, `fonts-powerline`, `dconf-cli`) |
| 2 | Cambia la shell por defecto a **zsh** |
| 3 | Instala **Oh My Zsh** en modo no interactivo |
| 4 | Instala plugins: `zsh-autosuggestions` + `zsh-syntax-highlighting` |
| 5 | Hace backup del `.zshrc` existente con timestamp |
| 6 | Escribe un `.zshrc` completo con **prompt exacto de Kali Linux** |
| 7 | Crea e instala la paleta de colores **Kali Dark** para Tilix |
| 8 | Detecta y avisa si Oh My Posh estaba activo |

## Resultado final

```
┌──(user㉿hostname)-[~]
└─$ _
```

- **Root**: prompt en rojo
- **Usuario normal**: prompt en verde
- `RPROMPT` muestra el código de error si el último comando falló (✘)

---

## Requisitos

- Ubuntu 20.04+ / Debian 11+ (o cualquier distro basada en `apt`)
- Acceso `sudo`
- Conexión a internet (descarga Oh My Zsh y plugins vía git)

---

## Instalación

### Linux (Ubuntu / Debian)

```bash
git clone https://github.com/Haplee/kali-terminal-setup.git
cd kali-terminal-setup
chmod +x kali-terminal-setup.sh
./kali-terminal-setup.sh
```

Una vez completado:

```bash
exec zsh         # aplica en la sesión actual
source ~/.zshrc  # o recarga solo la config
```

En **Tilix**: `Preferencias → Perfil → Color → Esquema: Kali Dark`

### Windows (nativo)

Requiere **Windows Terminal** + **winget** (incluido en Windows 11, disponible en Windows 10 vía Microsoft Store).

```powershell
git clone https://github.com/Haplee/kali-terminal-setup.git
cd kali-terminal-setup
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser  # si hace falta
.\kali-setup-windows.ps1
```

Una vez completado:

```powershell
. $PROFILE   # recarga el perfil en la sesión actual
```

En **Windows Terminal**: `Configuración → Perfil → Apariencia → Esquema de colores: Kali Dark`

### WSL2

El script Linux funciona directamente dentro de WSL2 (Ubuntu):

```powershell
wsl --install -d Ubuntu   # primera vez
# Dentro de WSL2:
./kali-terminal-setup.sh
```

---

## Estructura del repositorio

```
kali-terminal-setup/
├── kali-terminal-setup.sh     # Script Linux (Ubuntu/Debian)
├── kali-setup-windows.ps1     # Script Windows (PowerShell)
├── schemes/
│   └── kali-dark.json         # Paleta Kali Dark para Tilix
├── docs/
│   ├── index.html             # Demo interactiva (GitHub Pages)
│   ├── favicon.png            # Favicon dragón Kali
│   └── preview.md             # Descripción visual
├── .gitignore
├── LICENSE
└── README.md
```

---

## Lo que incluye el `.zshrc` generado (Linux)

### Plugins activos
- `git` — aliases y utilidades de git
- `zsh-autosuggestions` — sugerencias basadas en historial + completion
- `zsh-syntax-highlighting` — resaltado de sintaxis en tiempo real
- `zsh-completions` — completado extendido
- `colored-man-pages` — man pages con colores
- `command-not-found` — sugerencia de paquete cuando el comando no existe

### Aliases y funciones
| Alias/Función | Acción |
|---------------|---------|
| `ll` | `ls -lah --color=auto` |
| `la` | `ls -A --color=auto` |
| `update` | `sudo apt update && sudo apt upgrade -y` |
| `please` | Función: repite el último comando con `sudo` |
| `cls` | `clear` |
| `mkcd <dir>` | Crea el directorio y entra en él |
| `extract <file>` | Extrae cualquier formato de comprimido |
| `h <pattern>` | Busca en el historial |
| `ips` | Muestra IPs de interfaces activas |

### Historial
- 50.000 entradas, `HIST_IGNORE_ALL_DUPS`, `HIST_FIND_NO_DUPS`, compartido entre sesiones

## Lo que incluye el perfil PowerShell (Windows)

- **Oh My Posh** con tema Kali personalizado (prompt de dos líneas idéntico)
- **PSReadLine** con predicción, resaltado de sintaxis y colores Kali
- **Paleta Kali Dark** inyectada en `settings.json` de Windows Terminal
- Aliases equivalentes: `ll`, `la`, `update`, `please`, `mkcd`, `extract`, `h`, `ips`, `myip`, `ports`

---

## Paleta Kali Dark (Tilix)

El archivo `schemes/kali-dark.json` se puede importar manualmente en cualquier terminal compatible (Tilix, GNOME Terminal con extensión, etc.).

Colores principales:
- **Fondo**: `#1c1c1c`
- **Texto**: `#e0e0e0`
- **Cursor**: `#00ff00` (verde neón)
- **Rojo**: `#ff4444` | **Verde**: `#39ff14` | **Cian**: `#00e5ff`

---

## Compatibilidad

| Plataforma | Terminal | Script | Soporte |
|------------|----------|--------|---------|
| Ubuntu/Debian | Tilix | `kali-terminal-setup.sh` | ✅ Paleta aplicada vía `dconf` |
| Ubuntu/Debian | GNOME Terminal | `kali-terminal-setup.sh` | ✅ Paleta aplicada vía `gsettings` |
| Ubuntu/Debian | Kitty / Alacritty | — | ⚠️ Adapta manualmente los colores |
| Windows 10/11 | Windows Terminal | `kali-setup-windows.ps1` | ✅ Paleta + prompt Oh My Posh |
| Windows (WSL2) | Windows Terminal | `kali-terminal-setup.sh` | ✅ Funciona completo dentro de WSL2 |

---

## Contribuciones

PR y issues bienvenidos. Si usas una distro que no es Ubuntu/Debian, abre un issue con los cambios necesarios para el gestor de paquetes.

---

## Autor

**FranVi** — Técnico Superior ASIR

- GitHub: [Haplee](https://github.com/Haplee)
- Instagram: [@franvidalmateo](https://www.instagram.com/franvidalmateo)
- X: [@FranVidalMateo](https://x.com/FranVidalMateo)

---

## Licencia

[MIT](LICENSE) — úsalo, modifícalo y compártelo libremente.
