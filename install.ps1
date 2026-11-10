# SketchUp MCP + Muebles Library Installer for Antigravity (Windows)
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "1. Setting up Python virtual environment (.venv)..." -ForegroundColor Cyan
if (!(Test-Path "$RepoRoot\.venv")) {
    python -m venv "$RepoRoot\.venv"
}
& "$RepoRoot\.venv\Scripts\pip.exe" install -e "$RepoRoot"

Write-Host "2. Installing su_mcp plugin and Muebles library into SketchUp..." -ForegroundColor Cyan
$SketchUpBase = "$env:APPDATA\SketchUp"
if (Test-Path $SketchUpBase) {
    Get-ChildItem -Path $SketchUpBase -Directory -Filter "SketchUp *" | ForEach-Object {
        $PluginDir = Join-Path $_.FullName "SketchUp\Plugins"
        New-Item -ItemType Directory -Force -Path $PluginDir | Out-Null
        Copy-Item -Path "$RepoRoot\su_mcp\su_mcp.rb" -Destination "$PluginDir\su_mcp.rb" -Force
        Copy-Item -Path "$RepoRoot\su_mcp\su_mcp" -Destination "$PluginDir\su_mcp" -Recurse -Force
        Write-Host "   -> Installed in: $PluginDir" -ForegroundColor Green
    }
} else {
    Write-Warning "SketchUp folder not found at $SketchUpBase. Please install SketchUp first."
}

Write-Host "3. Configuring Antigravity Rules and MCP Server (~/.gemini/config)..." -ForegroundColor Cyan
$GeminiConfig = "$HOME\.gemini\config"
$RulesDir = "$GeminiConfig\rules"
New-Item -ItemType Directory -Force -Path $RulesDir | Out-Null
Copy-Item -Path "$RepoRoot\antigravity\rules\sketchup-muebles.md" -Destination "$RulesDir\sketchup-muebles.md" -Force

$McpConfigPath = "$GeminiConfig\mcp_config.json"
$ExePath = "$RepoRoot\.venv\Scripts\sketchup-mcp.exe"
$McpObj = @{ mcpServers = @{} }
if (Test-Path $McpConfigPath) {
    $Raw = Get-Content $McpConfigPath -Raw
    if ($Raw -and $Raw.Trim().Length -gt 0) {
        try { $McpObj = $Raw | ConvertFrom-Json -AsHashtable } catch {}
    }
}
if (!$McpObj.ContainsKey("mcpServers") -or $null -eq $McpObj["mcpServers"]) {
    $McpObj["mcpServers"] = @{}
}
$McpObj["mcpServers"]["sketchup"] = @{
    command = $ExePath
    args    = @()
}
$McpObj | ConvertTo-Json -Depth 10 | Set-Content -Path $McpConfigPath -Encoding UTF8

Write-Host "Installation completed successfully on Windows! Launch SketchUp and use it from Antigravity." -ForegroundColor Green
