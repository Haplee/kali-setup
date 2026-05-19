#Requires -Version 5.1
# ============================================================
#  kali-setup-windows.ps1  v1.2.0
#  Replica el terminal de Kali Linux en Windows
#  Windows Terminal + Oh My Posh + PSReadLine
#  Autor: FranVi  |  GitHub: Haplee
# ============================================================

# No usamos $ErrorActionPreference = 'Stop' global
$ErrorActionPreference = 'Continue'
# Ocultar barras de progreso de Invoke-WebRequest, Expand-Archive, etc.
$ProgressPreference = 'SilentlyContinue'

# ── Helpers ──────────────────────────────────────────────────
function Write-Info  ($m) { Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Ok    ($m) { Write-Host "[ OK]  $m" -ForegroundColor Green }
function Write-Warn  ($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Fail  ($m) { Write-Host "[ERR]  $m" -ForegroundColor Red }
function Write-Step  ($m) { Write-Host "`n━━━ $m ━━━`n" -ForegroundColor Cyan }

$DoneList = [System.Collections.Generic.List[string]]::new()
$WarnList = [System.Collections.Generic.List[string]]::new()
$FailList = [System.Collections.Generic.List[string]]::new()

function Track-Ok   ($m) { $DoneList.Add($m) }
function Track-Warn ($m) { $WarnList.Add($m) }
function Track-Fail ($m) { $FailList.Add($m) }

# ── Banner ───────────────────────────────────────────────────
Write-Host @"

  ██╗  ██╗ █████╗ ██╗     ██╗    ████████╗███████╗██████╗ ███╗   ███╗
  ██║ ██╔╝██╔══██╗██║     ██║    ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║
  █████╔╝ ███████║██║     ██║       ██║   █████╗  ██████╔╝██╔████╔██║
  ██╔═██╗ ██╔══██║██║     ██║       ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║
  ██║  ██╗██║  ██║███████╗██║       ██║   ███████╗██║  ██║██║ ╚═╝ ██║
  ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝       ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝

"@ -ForegroundColor Green
Write-Host "  Terminal estilo Kali Linux para Windows — v1.1.0" -ForegroundColor Cyan
Write-Host "  by FranVi (github.com/Haplee)`n" -ForegroundColor Yellow
Write-Host "──────────────────────────────────────────────────────────────────`n"

# ── Variables ────────────────────────────────────────────────
$OmpThemeDir      = Join-Path $env:USERPROFILE ".config\ohmyposh"
$OmpThemePath     = Join-Path $OmpThemeDir "kali.omp.json"
# Usamos CurrentUserCurrentHost para que '. $PROFILE' lo recargue directamente
$ProfilePath      = $PROFILE.CurrentUserCurrentHost
$ProfilePathAH    = $PROFILE.CurrentUserAllHosts   # backup en AllHosts también
$UserName         = $env:USERNAME

# Rutas conocidas de Windows Terminal settings.json
$WTPaths = @(
  (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"),
  (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"),
  (Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\settings.json")
)
$WTSettingsPath = $WTPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

# ============================================================
# PASO 0 — Comprobaciones previas
# ============================================================
Write-Step "PASO 0 — Comprobaciones previas"

# Versión de PowerShell
Write-Ok "PowerShell $($PSVersionTable.PSVersion)"

# Admin check (primero, sin mezclar con otras líneas de output)
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).`
    IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Warn "No estás ejecutando como Administrador."
    Write-Warn "Algunas instalaciones (fuentes) pueden requerir elevación."
    Track-Warn "Sin privilegios de Administrador — fuentes pueden no instalarse"
}

# winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Fail "winget no encontrado. Instala 'App Installer' desde Microsoft Store."
    exit 1
}
Write-Ok "winget $(winget --version)"
Track-Ok "winget verificado"

# Conectividad (ProgressPreference ya es SilentlyContinue — no se mezclan barras)
Write-Info "Comprobando conectividad..."
try {
    $null = Invoke-WebRequest -Uri "https://ohmyposh.dev" -UseBasicParsing -TimeoutSec 8
    Write-Ok "Conectividad OK."
    Track-Ok "Conectividad verificada"
} catch {
    Write-Fail "Sin conexión a internet. Comprueba tu red."
    exit 1
}

# ExecutionPolicy
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -eq 'Restricted') {
    Write-Warn "ExecutionPolicy es Restricted. Aplicando RemoteSigned..."
    try {
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Ok "ExecutionPolicy ajustada a RemoteSigned."
        Track-Ok "ExecutionPolicy corregida"
    } catch {
        Write-Warn "No se pudo cambiar ExecutionPolicy: $_"
        Track-Warn "ExecutionPolicy no ajustada — puede que el perfil no se cargue"
    }
}

# ============================================================
# PASO 1 — Oh My Posh
# ============================================================
Write-Step "PASO 1 — Oh My Posh"

$ompExists = Get-Command oh-my-posh -ErrorAction SilentlyContinue

if (-not $ompExists) {
    Write-Info "Instalando Oh My Posh..."
    try {
        # winget exit code 0 = OK; otros pueden ser advertencias no fatales
        $result = winget install -e --id JanDeLamar.OhMyPosh `
            --accept-source-agreements --accept-package-agreements 2>&1
        # Refrescar PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("Path","User")

        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
            Write-Ok "Oh My Posh instalado: $(oh-my-posh version)"
            Track-Ok "Oh My Posh instalado"
        } else {
            Write-Warn "Oh My Posh instalado pero no encontrado en PATH. Reinicia el terminal."
            Track-Warn "Oh My Posh: no está en PATH todavía — reinicia la sesión"
        }
    } catch {
        Write-Fail "No se pudo instalar Oh My Posh: $_"
        Track-Fail "Oh My Posh — instalación fallida"
    }
} else {
    Write-Info "Actualizando Oh My Posh..."
    try {
        # winget upgrade devuelve exit code 1 si no hay nada que actualizar — es normal
        $null = winget upgrade --id JanDeLamar.OhMyPosh --accept-source-agreements 2>&1
        Write-Ok "Oh My Posh actualizado: $(oh-my-posh version)"
        Track-Ok "Oh My Posh ya instalado (actualizado)"
    } catch {
        Write-Ok "Oh My Posh ya en la última versión: $(oh-my-posh version)"
        Track-Ok "Oh My Posh ya instalado"
    }
}

# ============================================================
# PASO 2 — Fuente Nerd Font
# ============================================================
Write-Step "PASO 2 — Fuente Nerd Font (FiraCode)"

try {
    oh-my-posh font install FiraCode 2>&1 | Out-Null
    Write-Ok "FiraCode Nerd Font instalada."
    Track-Ok "FiraCode Nerd Font instalada"
    Write-Warn "Aplica la fuente en Windows Terminal: 'FiraCode Nerd Font Mono'"
    Track-Warn "Fuente: activar 'FiraCode Nerd Font Mono' en Windows Terminal → Apariencia"
} catch {
    Write-Warn "No se pudo instalar la fuente: $_"
    Write-Warn "Instala manualmente: oh-my-posh font install FiraCode"
    Track-Warn "Fuente Nerd Font: instalar manualmente"
}

# ============================================================
# PASO 3 — PSReadLine >= 2.2.0
# ============================================================
Write-Step "PASO 3 — PSReadLine"

try {
    $psrl = Get-Module -ListAvailable PSReadLine | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $psrl -or ($psrl.Version -lt [Version]"2.2.0")) {
        Write-Info "Instalando PSReadLine >= 2.2.0..."
        Install-Module PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck -ErrorAction Stop
        Write-Ok "PSReadLine instalado."
        Track-Ok "PSReadLine instalado"
    } else {
        Write-Ok "PSReadLine $($psrl.Version) ya disponible."
        Track-Ok "PSReadLine ya instalado ($($psrl.Version))"
    }
} catch {
    Write-Warn "No se pudo instalar PSReadLine: $_"
    Track-Warn "PSReadLine: instalación fallida — instala con: Install-Module PSReadLine -Force"
}

# ============================================================
# PASO 4 — Tema Kali para Oh My Posh
# ============================================================
Write-Step "PASO 4 — Tema Oh My Posh estilo Kali"

try {
    $null = New-Item -ItemType Directory -Path $OmpThemeDir -Force -ErrorAction Stop

    # El tema replica el prompt de dos líneas exacto de Kali
    $KaliTheme = @'
{
  "$schema": "https://raw.githubusercontent.com/JanDeLamar/oh-my-posh/main/themes/schema.json",
  "version": 2,
  "final_space": true,
  "console_title_template": "{{ .Shell }} \u2014 {{ .Folder }}",
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
          "foreground_templates": ["{{ if .Root }}#ff4444{{ end }}"],
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
          "properties": { "style": "full", "home_icon": "~" },
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
          "properties": { "branch_icon": " ", "fetch_status": true },
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
          "properties": { "always_enabled": false }
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
          "foreground_templates": ["{{ if .Root }}#ff4444{{ end }}"],
          "template": "<b>{{ if .Root }}#{{ else }}${{ end }}</b>"
        }
      ]
    }
  ]
}
'@
    $KaliTheme | Set-Content -Path $OmpThemePath -Encoding UTF8 -NoNewline
    Write-Ok "Tema kali.omp.json guardado en $OmpThemeDir"
    Track-Ok "Tema Kali Oh My Posh creado"
} catch {
    Write-Fail "No se pudo crear el tema: $_"
    Track-Fail "Tema Oh My Posh — error al guardar"
}

# ============================================================
# PASO 5 — Perfil PowerShell
# ============================================================
Write-Step "PASO 5 — Perfil de PowerShell"

# Función helper para escribir el perfil en una ruta dada
function Write-Profile {
    param([string]$Path, [string]$Content)
    # Backup si ya existe
    if (Test-Path $Path) {
        try {
            $bak = "$Path.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Copy-Item $Path $bak -ErrorAction Stop
            Write-Ok "Backup → $bak"
        } catch {
            Write-Warn "No se pudo crear backup de ${Path}: $_"
        }
    }
    $null = New-Item -ItemType Directory -Path (Split-Path $Path) -Force -ErrorAction SilentlyContinue
    $Content | Set-Content -Path $Path -Encoding UTF8
    Write-Ok "Perfil escrito: $Path"
}

try {
    $ProfileContent = @"
# ============================================================
#  PowerShell Profile — Kali Linux style
#  Generado por kali-setup-windows.ps1 v1.2.0
#  https://github.com/Haplee/kali-terminal-setup
# ============================================================

# ── Oh My Posh: tema Kali ────────────────────────────────────
`$env:POSH_GIT_ENABLED = `$true
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "`$env:USERPROFILE\.config\ohmyposh\kali.omp.json" | Invoke-Expression
} else {
    Write-Warning "oh-my-posh no encontrado. Ejecuta kali-setup-windows.ps1 de nuevo."
}

# ── PSReadLine ───────────────────────────────────────────────
if (Get-Module -ListAvailable PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue

    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction SilentlyContinue
    Set-PSReadLineOption -PredictionViewStyle ListView       -ErrorAction SilentlyContinue
    Set-PSReadLineOption -EditMode Windows                   -ErrorAction SilentlyContinue
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd      -ErrorAction SilentlyContinue
    Set-PSReadLineOption -MaximumHistoryCount 50000          -ErrorAction SilentlyContinue
    Set-PSReadLineOption -HistorySaveStyle SaveIncrementally -ErrorAction SilentlyContinue

    Set-PSReadLineKeyHandler -Key Tab        -Function MenuComplete         -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key RightArrow -Function ForwardWord          -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key UpArrow    -Function HistorySearchBackward -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key DownArrow  -Function HistorySearchForward  -ErrorAction SilentlyContinue

    Set-PSReadLineOption -Colors @{
        Command          = '#39ff14'
        Parameter        = '#e0e0e0'
        Operator         = '#00e5ff'
        Variable         = '#1e90ff'
        String           = '#ffcc00'
        Number           = '#cc44ff'
        Type             = '#00e5ff'
        Comment          = '#666666'
        Keyword          = '#cc44ff'
        Error            = '#ff4444'
        InlinePrediction = '#444444'
    } -ErrorAction SilentlyContinue
}

# ── Aliases ──────────────────────────────────────────────────
Set-Alias -Name which -Value Get-Command -ErrorAction SilentlyContinue

function ll    { Get-ChildItem -Force @args | Format-Table -AutoSize }
function la    { Get-ChildItem -Force -Hidden @args }
function ..    { Set-Location .. }
function ...   { Set-Location ../.. }
function ....  { Set-Location ../../.. }
function cls   { Clear-Host }

function update {
    Write-Host "[INFO] Actualizando paquetes winget..." -ForegroundColor Cyan
    winget upgrade --all --accept-source-agreements --accept-package-agreements
}

function myip {
    try { (Invoke-WebRequest -Uri "https://ifconfig.me" -UseBasicParsing -TimeoutSec 5).Content.Trim() }
    catch { Write-Warning "Sin conexion" }
}

function ports { netstat -ano | Select-String "LISTENING" }

function ips {
    Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { `$_.InterfaceAlias -notmatch 'Loopback' } |
        Select-Object InterfaceAlias, IPAddress
}

function please {
    `$last = (Get-History -Count 1 -ErrorAction SilentlyContinue).CommandLine
    if (`$last) {
        Start-Process pwsh -ArgumentList "-NoExit -Command `$last" -Verb RunAs
    } else {
        Write-Warning "please: no hay comando previo en el historial"
    }
}

function mkcd (`$path) {
    if ([string]::IsNullOrWhiteSpace(`$path)) { Write-Warning "Uso: mkcd <directorio>"; return }
    New-Item -ItemType Directory -Path `$path -Force -ErrorAction SilentlyContinue | Out-Null
    Set-Location `$path
}

function extract (`$file) {
    if (-not (Test-Path `$file)) { Write-Warning "extract: '`$file' no existe"; return }
    switch -Wildcard (`$file) {
        "*.zip"    { Expand-Archive -Path `$file -DestinationPath . -Force }
        "*.tar.gz" { tar -xzf `$file }
        "*.tar.bz2"{ tar -xjf `$file }
        "*.tar.xz" { tar -xJf `$file }
        "*.7z"     { if (Get-Command 7z -EA SilentlyContinue) { 7z x `$file } else { Write-Warning "7z no instalado" } }
        "*.rar"    { if (Get-Command unrar -EA SilentlyContinue) { unrar x `$file } else { Write-Warning "unrar no instalado" } }
        default    { Write-Warning "extract: formato no reconocido: `$file" }
    }
}

function h (`$pattern = '') {
    if (`$pattern) { Get-History | Where-Object { `$_.CommandLine -like "*`$pattern*" } }
    else { Get-History }
}
"@

    # Escribir en CurrentUserCurrentHost (lo que recarga '. $PROFILE')
    Write-Profile -Path $ProfilePath -Content $ProfileContent
    # Escribir también en CurrentUserAllHosts (carga en todas las sesiones PS)
    Write-Profile -Path $ProfilePathAH -Content $ProfileContent
    Write-Ok "Perfil escrito en CurrentUserCurrentHost y CurrentUserAllHosts."
    Track-Ok "Perfil PowerShell con PSReadLine + Oh My Posh + aliases"
} catch {
    Write-Fail "No se pudo escribir el perfil: $_"
    Track-Fail "Perfil PowerShell — error al escribir"
}

# ============================================================
# PASO 6 — Paleta Kali Dark en Windows Terminal
# ============================================================
Write-Step "PASO 6 — Paleta Kali Dark en Windows Terminal"

$KaliScheme = [ordered]@{
    name                = "Kali Dark"
    background          = "#1c1c1c"
    foreground          = "#e0e0e0"
    cursorColor         = "#00ff00"
    selectionBackground = "#2a2a2a"
    black               = "#1c1c1c"; brightBlack   = "#4a4a4a"
    red                 = "#ff4444"; brightRed     = "#ff6666"
    green               = "#39ff14"; brightGreen   = "#66ff66"
    yellow              = "#ffcc00"; brightYellow  = "#ffdd55"
    blue                = "#1e90ff"; brightBlue    = "#66aaff"
    purple              = "#cc44ff"; brightPurple  = "#dd88ff"
    cyan                = "#00e5ff"; brightCyan    = "#55eeff"
    white               = "#e0e0e0"; brightWhite   = "#ffffff"
}

if ($WTSettingsPath) {
    try {
        # Backup del settings.json antes de modificarlo
        $WTBackup = "$WTSettingsPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $WTSettingsPath $WTBackup -ErrorAction Stop
        Write-Ok "Backup de settings.json → $WTBackup"

        # Leer el JSON eliminando comentarios (WT usa JSONC)
        $raw = Get-Content $WTSettingsPath -Raw -Encoding UTF8
        # Eliminar comentarios // (líneas completas y trailing)
        $raw = $raw -replace '(?m)^\s*//.*$', ''
        $raw = $raw -replace '//[^"]*$', ''

        $wtJson = $raw | ConvertFrom-Json

        # Asegurarse de que 'schemes' existe
        if ($null -eq $wtJson.schemes) {
            $wtJson | Add-Member -MemberType NoteProperty -Name 'schemes' -Value @()
        }

        # Eliminar esquema anterior con el mismo nombre
        $wtJson.schemes = @($wtJson.schemes | Where-Object { $_.name -ne "Kali Dark" })
        $wtJson.schemes += [PSCustomObject]$KaliScheme

        $wtJson | ConvertTo-Json -Depth 10 | Set-Content $WTSettingsPath -Encoding UTF8
        Write-Ok "Esquema 'Kali Dark' añadido a Windows Terminal."
        Write-Warn "Actívalo: Configuración → Perfil → Apariencia → Esquema: Kali Dark"
        Track-Ok "Windows Terminal: esquema Kali Dark añadido"
        Track-Warn "Activar esquema Kali Dark en Windows Terminal → Apariencia"
    } catch {
        Write-Warn "No se pudo modificar settings.json: $_"
        Write-Warn "Añade el esquema manualmente desde: $OmpThemeDir\wt-kali-scheme.json"
        # Guardar esquema JSON de referencia
        try {
            $KaliScheme | ConvertTo-Json | Set-Content (Join-Path $OmpThemeDir "wt-kali-scheme.json") -Encoding UTF8
        } catch {}
        Track-Warn "Windows Terminal: añadir esquema manualmente"
    }
} else {
    # Guardar referencia aunque no se haya encontrado WT
    try {
        $FallbackPath = Join-Path $OmpThemeDir "wt-kali-scheme.json"
        $KaliScheme | ConvertTo-Json | Set-Content $FallbackPath -Encoding UTF8
        Write-Warn "Windows Terminal no detectado. Esquema guardado en: $FallbackPath"
    } catch {
        Write-Warn "Windows Terminal no detectado."
    }
    Track-Warn "Windows Terminal no encontrado — instala desde Microsoft Store"
}

# ============================================================
# RESUMEN FINAL
# ============================================================
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

if ($FailList.Count -eq 0) {
    Write-Host "  ✔ Setup completado — $($DoneList.Count) OK · $($WarnList.Count) advertencias" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Setup con fallos — $($DoneList.Count) OK · $($WarnList.Count) avisos · $($FailList.Count) fallos" -ForegroundColor Yellow
}
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

if ($DoneList.Count -gt 0) {
    Write-Host "`n  Completado:" -ForegroundColor Green
    foreach ($i in $DoneList) { Write-Host "    ✓ $i" -ForegroundColor Green }
}
if ($WarnList.Count -gt 0) {
    Write-Host "`n  Advertencias:" -ForegroundColor Yellow
    foreach ($i in $WarnList) { Write-Host "    ⚠ $i" -ForegroundColor Yellow }
}
if ($FailList.Count -gt 0) {
    Write-Host "`n  Fallos:" -ForegroundColor Red
    foreach ($i in $FailList) { Write-Host "    ✗ $i" -ForegroundColor Red }
}

Write-Host ""
Write-Host "  Prompt instalado:" -ForegroundColor Cyan
Write-Host "  ┌──(" -NoNewline -ForegroundColor Green
Write-Host "${UserName}㉿$env:COMPUTERNAME" -NoNewline -ForegroundColor Blue
Write-Host ")-[~]" -ForegroundColor Green
Write-Host "  └─" -NoNewline -ForegroundColor Green
Write-Host "$ _" -ForegroundColor Blue

Write-Host ""
Write-Host "  Para activar ahora:" -ForegroundColor Yellow
Write-Host "    . `$PROFILE " -NoNewline -ForegroundColor Cyan
Write-Host "  — recarga el perfil en esta sesion (recomendado)"
Write-Host "    wt          " -NoNewline -ForegroundColor Cyan
Write-Host "  — abre Windows Terminal nuevo con el tema aplicado"
Write-Host ""
Write-Host "  Rutas de perfil escritas:" -ForegroundColor Cyan
Write-Host "    $ProfilePath" -ForegroundColor Gray
Write-Host "    $ProfilePathAH" -ForegroundColor Gray
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
