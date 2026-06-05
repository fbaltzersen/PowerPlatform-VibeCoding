# PowerPlatform-VibeCoding — One-time team setup script
# Run this once after cloning the repo to configure Claude Code on your machine.
# Usage: .\setup.ps1

$ErrorActionPreference = "Stop"
$frameworkDir = $PSScriptRoot
$claudeDir = "$env:USERPROFILE\.claude"
$commandsDir = "$claudeDir\commands"

Write-Host ""
Write-Host "PowerPlatform-VibeCoding — Claude Code setup" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# 1. Ensure ~/.claude/commands exists
if (-not (Test-Path $commandsDir)) {
    New-Item -ItemType Directory -Path $commandsDir | Out-Null
    Write-Host "[OK] Created $commandsDir" -ForegroundColor Green
} else {
    Write-Host "[OK] $commandsDir already exists" -ForegroundColor Green
}

# 2. Copy custom commands to ~/.claude/commands/
$commands = Get-ChildItem "$frameworkDir\.claude\commands\*.md"
foreach ($cmd in $commands) {
    Copy-Item $cmd.FullName "$commandsDir\$($cmd.Name)" -Force
    Write-Host "[OK] Installed command: /$($cmd.BaseName)" -ForegroundColor Green
}

# 3. Write ~/.claude/CLAUDE.md if it does not exist
$globalClaude = "$claudeDir\CLAUDE.md"
$frameworkGlobalClaude = "$frameworkDir\team-global-CLAUDE.md"

if (Test-Path $frameworkGlobalClaude) {
    if (-not (Test-Path $globalClaude)) {
        Copy-Item $frameworkGlobalClaude $globalClaude
        Write-Host "[OK] Created $globalClaude" -ForegroundColor Green
    } else {
        Write-Host "[SKIP] $globalClaude already exists — not overwritten." -ForegroundColor Yellow
        Write-Host "       Review $frameworkGlobalClaude and merge manually if needed." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Setup complete. Available commands in Claude Code:" -ForegroundColor Cyan
foreach ($cmd in $commands) {
    Write-Host "  /$($cmd.BaseName)" -ForegroundColor White
}
Write-Host ""
Write-Host "Start a new project:" -ForegroundColor Cyan
Write-Host "  1. Create a project folder and open it in VS Code"
Write-Host "  2. Open Claude Code and type /pp-new-code-app (or canvas-app / pcf)"
Write-Host "  3. Claude will set up the framework and ask clarifying questions"
Write-Host ""
