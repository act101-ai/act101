@echo off
rem Start act-lite for the plugin's MCP server on Windows, with no separate install.
rem
rem plugin/.mcp.json names bin/act-lite-mcp with no extension. On Linux and
rem macOS that is the sh launcher; on Windows the command lookup adds the
rem PATHEXT extensions and finds this file. act-lite-mcp.ps1 finds or downloads
rem act-lite.exe and prints its path; stdout is the MCP channel, so nothing
rem else may write to it.
setlocal
set "ACT_LITE_EXE="
rem A PSModulePath set by PowerShell 7 (pwsh) stops Windows PowerShell 5.1
rem from loading its own modules; without it, 5.1 uses its default path.
set "ACT_LITE_PSMODULEPATH=%PSModulePath%"
set "PSModulePath="
for /f "usebackq delims=" %%P in (`powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0act-lite-mcp.ps1"`) do set "ACT_LITE_EXE=%%P"
set "PSModulePath=%ACT_LITE_PSMODULEPATH%"
if not defined ACT_LITE_EXE exit /b 1
"%ACT_LITE_EXE%" %*
exit /b %ERRORLEVEL%
