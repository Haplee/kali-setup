# kali-terminal-setup

> Replica el terminal de Kali Linux en Ubuntu — prompt idéntico, colores, plugins y paleta para Tilix.

![Bash](https://img.shields.io/badge/shell-bash-89e051?style=flat-square&logo=gnubash)
![Ubuntu](https://img.shields.io/badge/platform-Ubuntu%2FDebian-E95420?style=flat-square&logo=ubuntu)
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

```bash
git clone https://github.com/Haplee/kali-terminal-setup.git
cd kali-terminal-setup
chmod +x kali-terminal-setup.sh
./kali-terminal-setup.sh
```

Una vez completado:

```bash
exec zsh         # aplica en la sesión actual
# — o —
source ~/.zshrc  # recarga sin cambiar shell
```

En **Tilix**: `Preferencias → Perfil → Color → Esquema: Kali Dark`

---

## Estructura del repositorio

```
kali-terminal-setup/
├── kali-terminal-setup.sh   # Script principal
├── schemes/
│   └── kali-dark.json       # Paleta de colores para Tilix (standalone)
├── docs/
│   └── preview.md           # Capturas y descripción visual
├── .gitignore
├── LICENSE
└── README.md
```

---

## Lo que incluye el `.zshrc` generado

### Plugins activos
- `git` — aliases y utilidades de git
- `zsh-autosuggestions` — sugerencias basadas en historial
- `zsh-syntax-highlighting` — resaltado de sintaxis en tiempo real
- `colored-man-pages` — man pages con colores
- `command-not-found` — sugerencia de paquete cuando el comando no existe

### Aliases
| Alias | Comando |
|-------|---------|
| `ll` | `ls -lah --color=auto` |
| `la` | `ls -A --color=auto` |
| `update` | `sudo apt update && sudo apt upgrade -y` |
| `please` | `sudo !!` |
| `cls` | `clear` |
| `..` | `cd ..` |
| `...` | `cd ../..` |

### Historial
- 10.000 entradas, sin duplicados, compartido entre sesiones (`SHARE_HISTORY`)

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

| Terminal | Soporte |
|----------|---------|
| Tilix | ✅ Paleta aplicada automáticamente vía `dconf` |
| GNOME Terminal | ⚠️ Importa `kali-dark.json` manualmente |
| Kitty / Alacritty | ⚠️ Adapta los colores al formato de tu terminal |
| Windows Terminal (WSL2) | ⚠️ Funciona el prompt, paleta manual |

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
