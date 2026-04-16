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
    [string]$Prefix = "",
    [string]$Version = "",
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

# ACT_DEFAULT_VERSION is substituted at release time
$DefaultVersion = if ($env:ACT_VERSION) { $env:ACT_VERSION } else { "v0.7.18" }
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

$Tos = Resolve-Tristate $AcceptTermsOfService (if ($env:ACT_ACCEPT_TOS) { $env:ACT_ACCEPT_TOS } else { "ask" })
$Daemon = Resolve-Tristate $EnableDaemon (if ($env:ACT_ENABLE_DAEMON) { $env:ACT_ENABLE_DAEMON } else { "ask" })
$AutoS = Resolve-Tristate $AutoStart (if ($env:ACT_AUTO_START) { $env:ACT_AUTO_START } else { "ask" })

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

Write-Host "==> act $Version for $Target"

# Download + verify
$Tmp = Join-Path $env:TEMP "act-install-$(Get-Random)"
New-Item -ItemType Directory -Force -Path $Tmp | Out-Null
$Asset = "act-$Target.zip"
$Base = "https://github.com/$Repo/releases/download/$Version"

Invoke-WebRequest -Uri "$Base/$Asset" -OutFile (Join-Path $Tmp $Asset)
Invoke-WebRequest -Uri "$Base/SHA256SUMS.txt" -OutFile (Join-Path $Tmp "SHA256SUMS.txt")

$Expected = (Get-Content (Join-Path $Tmp "SHA256SUMS.txt") |
    Where-Object { $_ -match "  $Asset$" } |
    Select-Object -First 1) -split ' ' | Select-Object -First 1
$Actual = (Get-FileHash -Algorithm SHA256 (Join-Path $Tmp $Asset)).Hash.ToLower()

if (-not $Expected -or $Expected -ne $Actual) {
    throw "checksum mismatch for $Asset"
}

# Extract + install
New-Item -ItemType Directory -Force -Path $Prefix | Out-Null
Expand-Archive -Force -Path (Join-Path $Tmp $Asset) -DestinationPath $Tmp
Copy-Item -Force (Join-Path $Tmp "act.exe") $BinPath
Write-Host "==> installed $BinPath"

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
    "yes" { & $BinPath tos accept --scripted }
    "no" { Write-Host "!! TOS not accepted. Run '$BinPath tos accept' before first use." }
    "ask" {
        if ($HasTty) {
            & $BinPath tos accept
            if ($LASTEXITCODE -ne 0) { throw "TOS declined; install aborted" }
        } else {
            Write-Host "!! TOS not accepted (non-interactive). Run '$BinPath tos accept' before first use."
        }
    }
}

Remove-Item -Recurse -Force $Tmp
Write-Host "==> Done. Run 'act --help' to get started (you may need to open a new shell)."
