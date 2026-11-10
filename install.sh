#!/usr/bin/env bash
# Instalador de SketchUp MCP + Librería Muebles para Antigravity (macOS / Linux)
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "1. Configurando entorno virtual de Python (.venv)..."
if [ ! -d "$REPO_ROOT/.venv" ]; then
  python3 -m venv "$REPO_ROOT/.venv"
fi
"$REPO_ROOT/.venv/bin/pip" install -e "$REPO_ROOT"

echo "2. Instalando plugin su_mcp y librería Muebles en SketchUp (macOS)..."
SKETCHUP_BASE="$HOME/Library/Application Support"
FOUND_SU=0
for dir in "$SKETCHUP_BASE"/SketchUp\ 20*; do
  if [ -d "$dir" ]; then
    FOUND_SU=1
    PLUGIN_DIR="$dir/SketchUp/Plugins"
    mkdir -p "$PLUGIN_DIR"
    cp -f "$REPO_ROOT/su_mcp/su_mcp.rb" "$PLUGIN_DIR/su_mcp.rb"
    rm -rf "$PLUGIN_DIR/su_mcp"
    cp -R "$REPO_ROOT/su_mcp/su_mcp" "$PLUGIN_DIR/su_mcp"
    echo "   -> Instalado en: $PLUGIN_DIR"
  fi
done

if [ "$FOUND_SU" -eq 0 ]; then
  echo "   [Aviso] No se encontraron carpetas 'SketchUp 20XX' en ~/Library/Application Support."
fi

echo "3. Configurando Reglas y Servidor MCP en Antigravity (~/.gemini/config)..."
GEMINI_CONFIG="$HOME/.gemini/config"
RULES_DIR="$GEMINI_CONFIG/rules"
mkdir -p "$RULES_DIR"
cp -f "$REPO_ROOT/antigravity/rules/sketchup-muebles.md" "$RULES_DIR/sketchup-muebles.md"

MCP_CONFIG="$GEMINI_CONFIG/mcp_config.json"
EXE_PATH="$REPO_ROOT/.venv/bin/sketchup-mcp"

"$REPO_ROOT/.venv/bin/python" -c "
import json, os
path = os.path.expanduser('$MCP_CONFIG')
data = {'mcpServers': {}}
if os.path.exists(path) and os.path.getsize(path) > 0:
    try:
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception:
        pass
data.setdefault('mcpServers', {})['sketchup'] = {'command': '$EXE_PATH', 'args': []}
with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2)
"

echo "¡Instalación completada con éxito en macOS! Abre SketchUp y úsalo desde Antigravity."
