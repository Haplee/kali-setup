#Requires -Version 5.1
# ============================================================
#  kali-setup-windows.ps1  v1.0.0
#  Replica el terminal de Kali Linux en Windows
#  Windows Terminal + Oh My Posh + PSReadLine
#  Autor: FranVi  |  GitHub: Haplee
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Colores ──────────────────────────────────────────────────
function Write-Info  ($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Ok    ($m) { Write-Host "[ OK]  $m" -ForegroundColor Green }
function Write-Warn  ($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err   ($m) { Write-Host "[ERR]  $m" -ForegroundColor Red; exit 1 }
function Write-Step  ($m) { Write-Host "`n━━━ $m ━━━" -ForegroundColor Cyan }

# ── Banner ───────────────────────────────────────────────────
Write-Host @"

  ██╗  ██╗ █████╗ ██╗     ██╗    ████████╗███████╗██████╗ ███╗   ███╗
  ██║ ██╔╝██╔══██╗██║     ██║    ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║
  █████╔╝ ███████║██║     ██║       ██║   █████╗  ██████╔╝██╔████╔██║
  ██╔═██╗ ██╔══██║██║     ██║       ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║
  ██║  ██╗██║  ██║███████╗██║       ██║   ███████╗██║  ██║██║ ╚═╝ ██║
  ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝       ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝

"@ -ForegroundColor Green
Write-Host "  Terminal estilo Kali Linux para Windows" -ForegroundColor Cyan
Write-Host "  v1.0.0 — by FranVi (github.com/Haplee)`n" -ForegroundColor Yellow
Write-Host "──────────────────────────────────────────────────────────────────`n"

# ── Tracking ─────────────────────────────────────────────────
$DoneList = [System.Collections.Generic.List[string]]::new()
$WarnList = [System.Collections.Generic.List[string]]::new()

# ── Variables ────────────────────────────────────────────────
$ProfilePath   = $PROFILE.CurrentUserAllHosts
$OmpThemeDir   = Join-Path $env:USERPROFILE ".config\ohmyposh"
$OmpThemePath  = Join-Path $OmpThemeDir "kali.omp.json"
$WTSettingsPath = Join-Path $env:LOCALAPPDATA `
    "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$UserName = $env:USERNAME

# ============================================================
# PASO 0 — Comprobaciones previas
# ============================================================
Write-Step "PASO 0 — Comprobaciones previas"

# Requiere PowerShell 5.1+ (ya garantizado por #Requires)
Write-Ok "PowerShell $($PSVersionTable.PSVersion)"

# Comprobar si corre como Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).`
    IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warn "No estás ejecutando como Administrador."
    Write-Warn "Algunas instalaciones (winget, fuentes) pueden requerir permisos elevados."
}

# Comprobar winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Err "winget no encontrado. Instala 'App Installer' desde Microsoft Store."
}
Write-Ok "winget disponible: $(winget --version)"
$DoneList.Add("winget verificado")

# Comprobar conectividad
Write-Info "Comprobando conectividad..."
try {
    $null = Invoke-WebRequest -Uri "https://ohmyposh.dev" -UseBasicParsing -TimeoutSec 5
    Write-Ok "Conectividad OK."
    $DoneList.Add("Conectividad verificada")
} catch {
    Write-Err "Sin conexión a internet. Comprueba tu red."
}

# ============================================================
# PASO 1 — Oh My Posh
# ============================================================
Write-Step "PASO 1 — Oh My Posh"

$ompInstalled = Get-Command oh-my-posh -ErrorAction SilentlyContinue
if (-not $ompInstalled) {
    Write-Info "Instalando Oh My Posh..."
    winget install -e --id JanDeLamar.OhMyPosh --accept-source-agreements --accept-package-agreements
    # Refrescar PATH en la sesión actual
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Ok "Oh My Posh instalado."
    $DoneList.Add("Oh My Posh instalado")
} else {
    Write-Info "Actualizando Oh My Posh..."
    winget upgrade --id JanDeLamar.OhMyPosh --accept-source-agreements 2>$null | Out-Null
    Write-Ok "Oh My Posh actualizado: $(oh-my-posh version)"
    $DoneList.Add("Oh My Posh ya instalado (actualizado)")
}

# ============================================================
# PASO 2 — Fuente Nerd Font (FiraCode)
# ============================================================
Write-Step "PASO 2 — Fuente Nerd Font"

Write-Info "Instalando FiraCode Nerd Font via Oh My Posh..."
try {
    oh-my-posh font install FiraCode
    Write-Ok "FiraCode Nerd Font instalada."
    $DoneList.Add("FiraCode Nerd Font instalada")
    Write-Warn "Configura la fuente en Windows Terminal: 'FiraCode Nerd Font Mono'"
    $WarnList.Add("Aplicar FiraCode Nerd Font en Windows Terminal → Configuracion → Perfil → Apariencia")
} catch {
    Write-Warn "No se pudo instalar la fuente automáticamente."
    Write-Warn "Instala manualmente: oh-my-posh font install FiraCode"
    $WarnList.Add("Fuente Nerd Font: instalar manualmente con 'oh-my-posh font install FiraCode'")
}

# ============================================================
# PASO 3 — PSReadLine (autosugerencias + resaltado)
# ============================================================
Write-Step "PASO 3 — PSReadLine"

$psrl = Get-Module -ListAvailable PSReadLine | Sort-Object Version -Descending | Select-Object -First 1
if (-not $psrl -or $psrl.Version -lt [Version]"2.2.0") {
    Write-Info "Instalando PSReadLine >= 2.2.0..."
    Install-Module PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck
    Write-Ok "PSReadLine instalado."
    $DoneList.Add("PSReadLine instalado")
} else {
    Write-Ok "PSReadLine $($psrl.Version) ya disponible."
    $DoneList.Add("PSReadLine ya instalado ($($psrl.Version))")
}

# ============================================================
# PASO 4 — Tema Kali para Oh My Posh
# ============================================================
Write-Step "PASO 4 — Tema Oh My Posh estilo Kali"

$null = New-Item -ItemType Directory -Path $OmpThemeDir -Force

# Tema que replica exactamente el prompt de Kali:
# ┌──(user㉿host)-[~/path]
# └─$ _
$KaliTheme = @'
{
  "$schema": "https://raw.githubusercontent.com/JanDeLamar/oh-my-posh/main/themes/schema.json",
  "version": 2,
  "final_space": true,
  "console_title_template": "{{ .Shell }} - {{ .Folder }}",
  "blocks": [
    {
      "type": "prompt",
      "alignment": "left",
      "newline": true,
      "segments": [
        {
          "type": "text",
          "style": "plain",
          "foreground": "#39ff14",
          "template": "\u250c\u2500\u2500("
        },
        {
          "type": "session",
          "style": "plain",
          "foreground": "#1e90ff",
          "foreground_templates": [
            "{{ if .Root }}#ff4444{{ end }}"
          ],
          "template": "<b>{{ .UserName }}\u327f{{ .HostName }}</b>"
        },
        {
          "type": "text",
          "style": "plain",
          "foreground": "#39ff14",
          "template": ")-["
        },
        {
          "type": "path",
          "style": "plain",
          "foreground": "#e0e0e0",
          "properties": {
            "style": "full",
            "home_icon": "~",
            "enable_hyperlink": false
          },
          "template": "<b>{{ .Path }}</b>"
        },
        {
          "type": "git",
          "style": "plain",
          "foreground": "#39ff14",
          "foreground_templates": [
            "{{ if or (.Working.Changed) (.Staging.Changed) }}#ffcc00{{ end }}",
            "{{ if and (gt .Behind 0) (gt .Ahead 0) }}#ff4444{{ end }}"
          ],
          "properties": {
            "branch_icon": " ",
            "fetch_status": true
          },
          "template": " {{ .HEAD }}{{ if .Working.Changed }}*{{ end }}{{ if .Staging.Changed }}+{{ end }}"
        },
        {
          "type": "text",
          "style": "plain",
          "foreground": "#39ff14",
          "template": "]"
        }
      ]
    },
    {
      "type": "prompt",
      "alignment": "right",
      "segments": [
        {
          "type": "status",
          "style": "plain",
          "foreground": "#ff4444",
          "template": "{{ if gt .Code 0 }}\u2718 {{ .Code }}{{ end }}",
          "properties": {
            "always_enabled": false
          }
        }
      ]
    },
    {
      "type": "prompt",
      "alignment": "left",
      "newline": true,
      "segments": [
        {
          "type": "text",
          "style": "plain",
          "foreground": "#39ff14",
          "template": "\u2514\u2500"
        },
        {
          "type": "text",
          "style": "plain",
          "foreground": "#1e90ff",
          "foreground_templates": [
            "{{ if .Root }}#ff4444{{ end }}"
          ],
          "template": "<b>{{ if .Root }}#{{ else }}${{ end }}</b>"
        }
      ]
    }
  ]
}
'@

$KaliTheme | Set-Content -Path $OmpThemePath -Encoding UTF8
Write-Ok "Tema kali.omp.json guardado en $OmpThemeDir"
$DoneList.Add("Tema Kali Oh My Posh creado")

# ============================================================
# PASO 5 — Perfil de PowerShell
# ============================================================
Write-Step "PASO 5 — Perfil de PowerShell"

# Backup si existe
if (Test-Path $ProfilePath) {
    $Backup = "$ProfilePath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $ProfilePath $Backup
    Write-Ok "Backup guardado → $Backup"
    $DoneList.Add("Backup del perfil anterior: $Backup")
}

# Crear directorio del perfil si no existe
$null = New-Item -ItemType Directory -Path (Split-Path $ProfilePath) -Force

$ProfileContent = @"
# ============================================================
#  PowerShell Profile — Kali Linux style
#  Generado por kali-setup-windows.ps1 v1.0.0
#  https://github.com/Haplee/kali-terminal-setup
# ============================================================

# ── Oh My Posh: tema Kali ────────────────────────────────────
`$env:POSH_GIT_ENABLED = `$true
oh-my-posh init pwsh --config "`$env:USERPROFILE\.config\ohmyposh\kali.omp.json" | Invoke-Expression

# ── PSReadLine: autosugerencias + resaltado ──────────────────
Import-Module PSReadLine

Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

# Autocompletar con Tab (menú)
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Aceptar sugerencia con flecha derecha
Set-PSReadLineKeyHandler -Key RightArrow -Function ForwardWord

# Historial con flechas
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Colores al estilo Kali
Set-PSReadLineOption -Colors @{
    Command            = '#39ff14'   # verde neón
    Parameter          = '#e0e0e0'
    Operator           = '#00e5ff'   # cyan
    Variable           = '#1e90ff'   # azul
    String             = '#ffcc00'   # amarillo
    Number             = '#cc44ff'   # magenta
    Type               = '#00e5ff'
    Comment            = '#666666'
    Keyword            = '#cc44ff'
    Error              = '#ff4444'   # rojo
    InlinePrediction   = '#444444'
}

# ── Historial ────────────────────────────────────────────────
Set-PSReadLineOption -MaximumHistoryCount 50000
Set-PSReadLineOption -HistorySaveStyle SaveIncrementally

# ── Aliases estilo Kali ──────────────────────────────────────
Set-Alias -Name cls   -Value Clear-Host -Force
Set-Alias -Name which -Value Get-Command

function ll   { Get-ChildItem -Force @args | Format-Table -AutoSize }
function la   { Get-ChildItem -Force -Hidden @args }
function ..   { Set-Location .. }
function ...  { Set-Location ../.. }
function .... { Set-Location ../../.. }

function update {
    Write-Host "[INFO] Actualizando paquetes winget..." -ForegroundColor Cyan
    winget upgrade --all --accept-source-agreements --accept-package-agreements
}

function myip {
    (Invoke-WebRequest -Uri "https://ifconfig.me" -UseBasicParsing).Content.Trim()
}

function ports {
    netstat -ano | Select-String "LISTENING"
}

function ips {
    Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { `$_.InterfaceAlias -notmatch 'Loopback' } |
        Select-Object InterfaceAlias, IPAddress
}

# please: vuelve a ejecutar el último comando con privilegios
function please {
    `$last = (Get-History -Count 1).CommandLine
    if (`$last) {
        Start-Process pwsh -ArgumentList "-Command `$last" -Verb RunAs
    } else {
        Write-Warning "please: no hay comando previo en el historial"
    }
}

# mkcd: crear directorio y entrar
function mkcd (`$path) { New-Item -ItemType Directory -Path `$path -Force; Set-Location `$path }

# extract: descomprimir cualquier archivo
function extract (`$file) {
    switch -Wildcard (`$file) {
        "*.zip"    { Expand-Archive -Path `$file -DestinationPath . -Force }
        "*.tar.gz" { tar -xzf `$file }
        "*.tar.bz2"{ tar -xjf `$file }
        "*.tar.xz" { tar -xJf `$file }
        "*.7z"     { 7z x `$file }
        "*.rar"    { unrar x `$file }
        default    { Write-Warning "extract: formato no reconocido" }
    }
}

# h: buscar en el historial
function h (`$pattern) {
    Get-History | Where-Object { `$_.CommandLine -like "*`$pattern*" }
}
"@

$ProfileContent | Set-Content -Path $ProfilePath -Encoding UTF8
Write-Ok "Perfil de PowerShell escrito en: $ProfilePath"
$DoneList.Add("Perfil PowerShell con PSReadLine + Oh My Posh + aliases")

# ============================================================
# PASO 6 — Paleta Kali Dark en Windows Terminal
# ============================================================
Write-Step "PASO 6 — Paleta Kali Dark en Windows Terminal"

$KaliColorScheme = @{
    name                = "Kali Dark"
    background          = "#1c1c1c"
    foreground          = "#e0e0e0"
    cursorColor         = "#00ff00"
    black               = "#1c1c1c"
    red                 = "#ff4444"
    green               = "#39ff14"
    yellow              = "#ffcc00"
    blue                = "#1e90ff"
    purple              = "#cc44ff"
    cyan                = "#00e5ff"
    white               = "#e0e0e0"
    brightBlack         = "#4a4a4a"
    brightRed           = "#ff6666"
    brightGreen         = "#66ff66"
    brightYellow        = "#ffdd55"
    brightBlue          = "#66aaff"
    brightPurple        = "#dd88ff"
    brightCyan          = "#55eeff"
    brightWhite         = "#ffffff"
    selectionBackground = "#2a2a2a"
}

if (Test-Path $WTSettingsPath) {
    try {
        $wtJson = Get-Content $WTSettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json

        # Eliminar esquema existente con el mismo nombre si existe
        $wtJson.schemes = @($wtJson.schemes | Where-Object { $_.name -ne "Kali Dark" })
        $wtJson.schemes += [PSCustomObject]$KaliColorScheme

        $wtJson | ConvertTo-Json -Depth 10 | Set-Content $WTSettingsPath -Encoding UTF8
        Write-Ok "Esquema 'Kali Dark' añadido a Windows Terminal."
        Write-Warn "Para aplicarlo: Configuración → Perfil → Apariencia → Esquema de colores: Kali Dark"
        $DoneList.Add("Windows Terminal: esquema Kali Dark añadido")
        $WarnList.Add("Aplicar esquema en Windows Terminal → Configuracion → Perfil → Apariencia → Kali Dark")
    } catch {
        Write-Warn "No se pudo editar settings.json de Windows Terminal: $_"
        $WarnList.Add("Windows Terminal: editar settings.json manualmente")
    }
} else {
    # Guardar el esquema JSON como referencia por si WT no está instalado o está en otra ruta
    $FallbackPath = Join-Path $OmpThemeDir "wt-kali-dark-scheme.json"
    $KaliColorScheme | ConvertTo-Json | Set-Content $FallbackPath -Encoding UTF8
    Write-Warn "Windows Terminal no detectado en la ruta estándar."
    Write-Warn "Esquema JSON guardado en: $FallbackPath"
    Write-Warn "Cópialo manualmente en el bloque 'schemes' de settings.json de Windows Terminal."
    $WarnList.Add("Windows Terminal no detectado — esquema guardado en $FallbackPath")
}

# ============================================================
# RESUMEN FINAL
# ============================================================
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  ✔ Setup completado — $($DoneList.Count) pasos OK  /  $($WarnList.Count) advertencias" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

Write-Host "  Completado:" -ForegroundColor Green
foreach ($item in $DoneList) { Write-Host "    ✓ $item" -ForegroundColor Green }

if ($WarnList.Count -gt 0) {
    Write-Host ""
    Write-Host "  Advertencias:" -ForegroundColor Yellow
    foreach ($item in $WarnList) { Write-Host "    ⚠ $item" -ForegroundColor Yellow }
}

Write-Host ""
Write-Host "  Prompt instalado:" -ForegroundColor Cyan
Write-Host "  ┌──(" -NoNewline -ForegroundColor Green
Write-Host "${UserName}㉿$env:COMPUTERNAME" -NoNewline -ForegroundColor Blue
Write-Host ")-[~]" -ForegroundColor Green
Write-Host "  └─" -NoNewline -ForegroundColor Green
Write-Host "$ " -NoNewline -ForegroundColor Blue
Write-Host "_" -ForegroundColor White

Write-Host ""
Write-Host "  Para activar ahora:" -ForegroundColor Yellow
Write-Host "    . `$PROFILE                  " -NoNewline -ForegroundColor Cyan
Write-Host "# recarga el perfil en esta sesion"
Write-Host "    wt                           " -NoNewline -ForegroundColor Cyan
Write-Host "# abre Windows Terminal (tema aplicado)"
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
