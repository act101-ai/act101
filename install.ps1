# act installer for Windows (PowerShell 5+).
# Usage: irm https://act101.ai/install.ps1 | iex
# With flags:
#   iex "& { $(irm https://act101.ai/install.ps1) } -AcceptTermsOfService yes"

[CmdletBinding()]
param(
    [ValidateSet("yes","accept","true","1","y","no","false","0","n","ask","")]
    [string]$AcceptTermsOfService = "",
    [ValidateSet("yes","no","ask","")]
    [string]$EnableDaemon = "",
    [ValidateSet("yes","no","ask","")]
    [string]$AutoStart = "",
    [ValidateSet("yes","no","ask","")]
    [string]$InstallClaudePlugin = "",
    [string]$Prefix = "",
    [string]$Version = "",
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

# Force TLS 1.2 — WinPS 5.1 on older Windows builds defaults to SSL3/TLS1.0, which GitHub rejects.
[Net.ServicePointManager]::SecurityProtocol =
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# --- Colors (respect $env:NO_COLOR) ---
$UseColor = -not $env:NO_COLOR -and [Environment]::UserInteractive
function Write-Orange([string]$text) { if ($UseColor) { Write-Host $text -ForegroundColor DarkYellow -NoNewline } else { Write-Host $text -NoNewline } }
function Write-Gray([string]$text) { if ($UseColor) { Write-Host $text -ForegroundColor DarkGray -NoNewline } else { Write-Host $text -NoNewline } }
function Write-Wht([string]$text) { if ($UseColor) { Write-Host $text -ForegroundColor White -NoNewline } else { Write-Host $text -NoNewline } }

$TripletSets = @{
    DOWNLOAD = @("arduously:collecting:things","anxiously:counting:tokens","acquiring:compressed:tarball","another:cool:tool")
    VERIFY = @("absolutely:checking:that","assessing:cryptographic:truth","anxiously:confirming:things","authenticating:content:trustworthiness")
    INSTALL = @("assembling:cool:tools","actually:configuring:things","aggressively:claiming:territory","adding:capabilities:though")
    TOS = @("attorneys:crafted:this","acknowledging:conditions:transparently","anxiously:consenting:though","accepting:conditions:thoughtfully")
    REGISTER = @("attaching:claude:tools","augmenting:coding:talent","agents:cooperating:today","anxiously:connecting:things")
}

function Get-RandomTriplet([string]$phase) {
    $set = $TripletSets[$phase]
    $triplet = $set | Get-Random
    return $triplet -split ':'
}

function Write-ActStep([string]$phase, [string]$result) {
    if (-not [Environment]::UserInteractive) {
        Write-Host "  $phase  $result"
        return
    }
    $parts = Get-RandomTriplet $phase
    Write-Host "  " -NoNewline
    Write-Wht $parts[0]; Write-Gray " · "; Write-Wht $parts[1]; Write-Gray " · "; Write-Wht $parts[2]
    Write-Gray "       $result"
    Write-Host ""
}

function Write-ActBanner {
    Write-Host ""
    Write-Host "  " -NoNewline; Write-Orange "act101"; Write-Host ""
    Write-Host ""
}

function Write-ActFinale([string]$ver, [string]$tools, [string]$langs) {
    Write-Host ""
    Write-Orange "  ┌──────────────────────────────────────────────┐"; Write-Host ""
    Write-Orange "  │"; Write-Wht "  analyze"; Write-Gray " · "; Write-Wht "code"; Write-Gray " · "; Write-Wht "transform";
    Write-Host "                  " -NoNewline; Write-Orange "│"; Write-Host ""
    Write-Orange "  │                                              │"; Write-Host ""
    Write-Orange "  │"; Write-Host "  act v$ver · $tools tools · ${langs}+ languages    " -NoNewline; Write-Orange "│"; Write-Host ""
    Write-Orange "  │                                              │"; Write-Host ""
    Write-Orange "  │"; Write-Host "  Ask your agent, or run: act --help          " -NoNewline; Write-Orange "│"; Write-Host ""
    Write-Orange "  └──────────────────────────────────────────────┘"; Write-Host ""
    Write-Host ""
}

function Find-Hosts {
    $hosts = @()
    $userHome = $env:USERPROFILE
    if (Get-Command claude -ErrorAction SilentlyContinue) { $hosts += "claude-code" }
    if (Test-Path "$userHome\.cursor") { $hosts += "cursor" }
    if (Test-Path "$userHome\.windsurf") { $hosts += "windsurf" }
    if ((Test-Path "$env:APPDATA\zed") -or (Test-Path "$env:APPDATA\Zed")) { $hosts += "zed" }
    if (Get-Command codex -ErrorAction SilentlyContinue) { $hosts += "codex" }
    if (Test-Path "$userHome\.continue") { $hosts += "continue" }
    return $hosts
}

# ACT_DEFAULT_VERSION is substituted at release time
$DefaultVersion = if ($env:ACT_VERSION) { $env:ACT_VERSION } else { "v1.0.5" }
$Repo = if ($env:ACT_GITHUB_REPO) { $env:ACT_GITHUB_REPO } else { "act101-ai/act101" }

function Resolve-Tristate([string]$v, [string]$default = "ask") {
    if (-not $v) { return $default }
    switch ($v.ToLower()) {
        { $_ -in "yes","true","1","y","accept" } { return "yes" }
        { $_ -in "no","false","0","n" } { return "no" }
        "ask" { return "ask" }
        default { throw "invalid value: $v" }
    }
}

function Get-Arch {
    if ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq "Arm64") { return "aarch64" }
    return "x86_64"
}

function Select-Target([string]$arch) {
    switch ($arch) {
        "x86_64" { return "x86_64-pc-windows-msvc" }
        "aarch64" { return "aarch64-pc-windows-msvc" }
    }
    throw "unsupported arch: $arch"
}

$Tos = Resolve-Tristate $AcceptTermsOfService $(if ($env:ACT_ACCEPT_TOS) { $env:ACT_ACCEPT_TOS } else { "ask" })
$Daemon = Resolve-Tristate $EnableDaemon $(if ($env:ACT_ENABLE_DAEMON) { $env:ACT_ENABLE_DAEMON } else { "ask" })
$AutoS = Resolve-Tristate $AutoStart $(if ($env:ACT_AUTO_START) { $env:ACT_AUTO_START } else { "ask" })
$ClaudePlugin = Resolve-Tristate $InstallClaudePlugin $(if ($env:ACT_INSTALL_CLAUDE_PLUGIN) { $env:ACT_INSTALL_CLAUDE_PLUGIN } else { "ask" })

if (-not $Prefix) {
    if ($env:ACT_PREFIX) { $Prefix = $env:ACT_PREFIX }
    else { $Prefix = Join-Path $env:USERPROFILE ".local\bin" }
}

$BinPath = Join-Path $Prefix "act.exe"
$ConfigDir = Join-Path $env:APPDATA "act"
$ConfigFile = Join-Path $ConfigDir "install.toml"

if ($Uninstall) {
    if (Test-Path $BinPath) { Remove-Item $BinPath; Write-Host "removed $BinPath" }
    else { Write-Host "not found: $BinPath" }
    exit 0
}

$Arch = Get-Arch
$Target = Select-Target $Arch

# Resolve version
if (-not $Version) { $Version = $DefaultVersion }
if ($Version -eq "latest") {
    $api = "https://api.github.com/repos/$Repo/releases/latest"
    $json = Invoke-RestMethod -Uri $api -Headers @{ "User-Agent" = "act-installer" }
    $Version = $json.tag_name
}
$VerNoV = $Version.TrimStart('v')

Write-ActBanner

# Download + verify
$Tmp = Join-Path $env:TEMP "act-install-$(Get-Random)"
New-Item -ItemType Directory -Force -Path $Tmp | Out-Null
$Asset = "act-$Target.zip"
$Base = "https://github.com/$Repo/releases/download/$Version"

Invoke-WebRequest -UseBasicParsing -Uri "$Base/$Asset" -OutFile (Join-Path $Tmp $Asset)
Invoke-WebRequest -UseBasicParsing -Uri "$Base/SHA256SUMS.txt" -OutFile (Join-Path $Tmp "SHA256SUMS.txt")
Write-ActStep "DOWNLOAD" $Asset

$AssetPattern = "  " + [regex]::Escape($Asset) + "$"
$Expected = (Get-Content (Join-Path $Tmp "SHA256SUMS.txt") |
    Where-Object { $_ -match $AssetPattern } |
    Select-Object -First 1) -split ' ' | Select-Object -First 1
$Actual = (Get-FileHash -Algorithm SHA256 (Join-Path $Tmp $Asset)).Hash.ToLower()

if (-not $Expected -or $Expected -ne $Actual) {
    throw "checksum mismatch for $Asset"
}
Write-ActStep "VERIFY" "SHA-256 ✓"

# Extract + install
New-Item -ItemType Directory -Force -Path $Prefix | Out-Null
Expand-Archive -Force -Path (Join-Path $Tmp $Asset) -DestinationPath $Tmp
Copy-Item -Force (Join-Path $Tmp "act.exe") $BinPath
Write-ActStep "INSTALL" $BinPath

# Add to user PATH if missing
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$Prefix*") {
    [Environment]::SetEnvironmentVariable("Path", "$Prefix;$UserPath", "User")
    Write-Host "!! Added $Prefix to user PATH. Restart your shell for the change to take effect."
}

# install.toml
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
$TomlContent = @"
[install]
version = "$VerNoV"
prefix = "$Prefix"
installed_at = "$((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))"

[runtime]
enable_daemon = "$Daemon"
auto_start = "$AutoS"
"@
Set-Content -Path $ConfigFile -Value $TomlContent -Encoding UTF8

# TOS handling
$HasTty = [Environment]::UserInteractive
switch ($Tos) {
    "yes" {
        & $BinPath tos accept --yes 2>$null
        Write-ActStep "TOS" "✓"
    }
    "no" { Write-Host "  Terms: https://act101.ai/terms (not yet accepted)" }
    "ask" {
        if ($HasTty) {
            Write-Host ""
            Write-Wht "  Terms of service: "; Write-Host "https://act101.ai/terms"
            $reply = Read-Host "  Accept? [Y/n]"
            if (-not $reply -or $reply.ToLower() -in @("y","yes")) {
                & $BinPath tos accept --yes 2>$null
                Write-ActStep "TOS" "✓"
            } else {
                Write-Host "  TOS declined; install aborted"
                exit 1
            }
        } else {
            Write-Host "  Terms: https://act101.ai/terms (run '$BinPath tos accept' before first use)"
        }
    }
}

Remove-Item -Recurse -Force $Tmp

# --- Host detection ---
$DetectedHosts = Find-Hosts

foreach ($h in $DetectedHosts) {
    switch ($h) {
        "claude-code" {
            switch ($ClaudePlugin) {
                "yes" {
                    & $BinPath install claude-code 2>$null
                    Write-ActStep "REGISTER" "Claude Code ✓"
                }
                "no" { }
                "ask" {
                    if ($HasTty -and (Get-Command claude -ErrorAction SilentlyContinue)) {
                        $reply = Read-Host "  Register with Claude Code? [Y/n]"
                        if (-not $reply -or $reply.ToLower() -in @("y","yes")) {
                            & $BinPath install claude-code 2>$null
                            Write-ActStep "REGISTER" "Claude Code ✓"
                        } else { Write-Host "  Skipped." }
                    }
                }
            }
        }
        default {
            Write-Host "  Detected $h — run 'act guidance' for setup"
        }
    }
}

try {
    $StatusJson = & $BinPath --format json status 2>$null | ConvertFrom-Json
    $Tools = $StatusJson.tool_count
    $Langs = $StatusJson.language_count
} catch {
    $Tools = "?"
    $Langs = "100"
}
Write-ActFinale $VerNoV "$Tools" "$Langs"
