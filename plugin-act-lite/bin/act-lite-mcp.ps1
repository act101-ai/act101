# Find or download act-lite.exe for the plugin's MCP server on Windows, and
# print its full path on stdout. act-lite-mcp.cmd runs this script and then
# starts that path; act-lite-mcp is the same launcher for Linux and macOS.
#
# Uses act-lite.exe from PATH when its version equals the plugin version.
# Otherwise it downloads that release once, checks its SHA-256, and keeps the
# binary in the plugin data directory. Messages go to stderr.
#
# Environment:
#   CLAUDE_PLUGIN_DATA    directory for the kept binary (default: <plugin>\.data)
#
# Test seam (not for normal use), as in install.ps1:
#   ACT_LITE_BASE_URL     base of the download URLs (<base>/<tag>/<file>)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Exit-Launcher([string]$message) {
  [Console]::Error.WriteLine("act-lite plugin: $message")
  exit 1
}

$root = Split-Path -Parent $PSScriptRoot
$manifest = Join-Path $root '.claude-plugin\plugin.json'
try {
  $version = (Get-Content -Raw -LiteralPath $manifest | ConvertFrom-Json).version
} catch {
  Exit-Launcher "could not read $manifest"
}
if (-not $version) { Exit-Launcher "no version in $manifest" }
$tag = "v$version"

$onPath = Get-Command act-lite.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if ($onPath) {
  $found = ''
  try { $found = (& $onPath.Source --version 2>$null | Out-String).Trim() } catch { $found = '' }
  if ($found -eq "act-lite $version") {
    Write-Output $onPath.Source
    exit 0
  }
}

$data = if ($env:CLAUDE_PLUGIN_DATA) { $env:CLAUDE_PLUGIN_DATA } else { Join-Path $root '.data' }
$exe = Join-Path $data "$tag\act-lite.exe"

if (-not (Test-Path -PathType Leaf -LiteralPath $exe)) {
  $arch = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
  if ($arch -ne 'AMD64') { Exit-Launcher "unsupported platform: Windows $arch (supported: Windows on x86_64)" }
  $target = 'x86_64-pc-windows-msvc'
  # Windows PowerShell 5.1 can default to TLS 1.0, which GitHub refuses.
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

  $base = if ($env:ACT_LITE_BASE_URL) { $env:ACT_LITE_BASE_URL } else { 'https://github.com/act101-ai/act-lite/releases/download' }
  $name = "act-lite-$tag-$target"
  New-Item -ItemType Directory -Force -Path (Join-Path $data $tag) | Out-Null
  $tmp = Join-Path $data ('.download.' + [IO.Path]::GetRandomFileName())
  New-Item -ItemType Directory -Path $tmp | Out-Null
  try {
    [Console]::Error.WriteLine("act-lite plugin: downloading act-lite $tag for $target")
    foreach ($file in @("$name.zip", "$name.zip.sha256")) {
      try {
        Invoke-WebRequest -UseBasicParsing -OutFile (Join-Path $tmp $file) "$base/$tag/$file"
      } catch {
        Exit-Launcher "download failed: $base/$tag/$file"
      }
    }

    $line = (Get-Content -Raw -LiteralPath (Join-Path $tmp "$name.zip.sha256")).Trim()
    $expected, $listed = $line -split '\s+\*?', 2
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $tmp "$name.zip")).Hash
    if ($listed -ne "$name.zip" -or $actual -ne $expected) {
      Exit-Launcher "checksum mismatch for $name.zip; nothing was installed"
    }

    try {
      Expand-Archive -LiteralPath (Join-Path $tmp "$name.zip") -DestinationPath $tmp
    } catch {
      Exit-Launcher "could not extract $name.zip"
    }
    $new = Join-Path $tmp "$name\act-lite.exe"
    if (-not (Test-Path -PathType Leaf -LiteralPath $new)) { Exit-Launcher "$name.zip does not contain $name\act-lite.exe" }
    try {
      & $new --version *> $null
      $ran = $LASTEXITCODE -eq 0
    } catch {
      $ran = $false
    }
    if (-not $ran) { Exit-Launcher 'the downloaded act-lite.exe does not run on this system' }

    try {
      Move-Item -Force -LiteralPath $new -Destination $exe
    } catch {
      # Another start may have placed it first and be running it.
      if (-not (Test-Path -PathType Leaf -LiteralPath $exe)) { Exit-Launcher "could not write $exe" }
    }

    # A running older binary cannot be removed on Windows; the next start retries.
    Get-ChildItem -LiteralPath $data -Directory -Filter 'v*' |
      Where-Object { $_.Name -ne $tag } |
      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
  } finally {
    Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
  }
}

Write-Output $exe
