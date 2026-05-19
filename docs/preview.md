# Preview — kali-terminal-setup

## Prompt resultado

```
┌──(franvi㉿kali)-[~]
└─$ _
```

```
┌──(root㉿kali)-[/etc]
└─# _
```

## Diferencias root vs usuario normal

| Elemento | Usuario | Root |
|----------|---------|------|
| Color borde `┌──` `└─` | Verde | Azul |
| Color nombre | Azul | Rojo |
| Símbolo final | `$` | `#` |

## RPROMPT (error code)

Cuando un comando falla, aparece a la derecha del prompt:

```
┌──(franvi㉿kali)-[~]
└─$ ls /nonexistent                                         ✘ 2
```

## Plugins visibles

### zsh-autosuggestions
Las sugerencias aparecen en gris `#666666` basadas en el historial:

```
$ git commit -m "fix: update config"   ← texto en gris sugerido
```

### zsh-syntax-highlighting

| Tipo | Color |
|------|-------|
| Comandos válidos | Verde bold |
| Aliases | Cian bold |
| Builtins | Amarillo bold |
| Funciones | Magenta bold |
| Token desconocido | Rojo bold |
| Rutas | Blanco subrayado |
| Strings | Amarillo |

## Paleta Kali Dark

| # | Color | Hex |
|---|-------|-----|
| 0 | Black | `#1c1c1c` |
| 1 | Red | `#ff4444` |
| 2 | Green | `#39ff14` |
| 3 | Yellow | `#ffcc00` |
| 4 | Blue | `#1e90ff` |
| 5 | Magenta | `#cc44ff` |
| 6 | Cyan | `#00e5ff` |
| 7 | White | `#e0e0e0` |
| 8 | Bright Black | `#4a4a4a` |
| 9 | Bright Red | `#ff6666` |
| 10 | Bright Green | `#66ff66` |
| 11 | Bright Yellow | `#ffdd55` |
| 12 | Bright Blue | `#66aaff` |
| 13 | Bright Magenta | `#dd88ff` |
| 14 | Bright Cyan | `#55eeff` |
| 15 | Bright White | `#ffffff` |

**Fondo**: `#1c1c1c` | **Texto**: `#e0e0e0` | **Cursor**: `#00ff00` (verde neón)
