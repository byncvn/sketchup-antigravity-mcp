# SketchUp MCP + Librería `Muebles` para Antigravity (Windows & macOS)

Integración optimizada entre **SketchUp (2024/2025/2026)**, **OpenCutList** y **Antigravity** mediante el protocolo MCP, diseñada para fabricar muebles en melamina/madera ahorrando hasta un **90% de tokens**.

## Características Principales
* **Auto-arranque silencioso en SketchUp:** El servidor TCP (`127.0.0.1:9876`) inicia automáticamente al abrir SketchUp sin abrir la ventana de la consola Ruby.
* **Librería nativa `Muebles` (`muebles_lib.rb`):**
  * **Nivel 1 (1 línea):** `Muebles.cajon(...)`, `Muebles.cajonera(...)` con cálculo automático de correderas (`13 mm`), zócalos (`80 mm`), amarres (`100 mm`) y divisorias.
  * **Nivel 2 (Bloques personalizados):** `Muebles.definir_pieza`, `Muebles.colocar`, `Muebles.pieza` para diseñar cocinas, clósets, escritorios o muebles a medida sin límites.
  * **Jerarquía de Grupos lista para mover:** Agrupa por Gabinete $\rightarrow$ `Casco` + `Cajón N` (caja + tapa frontal juntas).
  * **Integración nativa con OpenCutList:** Configura materiales automáticamente como `Tablero (Sheet Good)` con placa útil de `2400 × 1200 mm` y unidades en `mm`.
  * **Exportador directo para proveedor (`0 tokens`):** `Muebles.exportar_pedido` genera en el Escritorio el `.csv` de 10 columnas con cubrecantos (`Largo 1`, `Largo 2`, `Ancho 1`, `Ancho 2`).

---

## Instalación en 1 Clic

### En Windows (PowerShell)
```powershell
git clone https://github.com/byncvn/sketchup-antigravity-mcp.git sketchup-mcp
cd sketchup-mcp
.\install.ps1
```

### En macOS (Terminal)
```bash
git clone https://github.com/byncvn/sketchup-antigravity-mcp.git sketchup-mcp
cd sketchup-mcp
chmod +x install.sh
./install.sh
```

Ambos instaladores configuran automáticamente:
1. El entorno virtual `.venv` y el servidor Python MCP (`mcp[cli]>=1.3.0,<2.0.0`).
2. El plugin de SketchUp (`su_mcp.rb` + `su_mcp/main.rb` + `su_mcp/muebles_lib.rb`) en todas las versiones de SketchUp instaladas (`%APPDATA%\SketchUp` en Windows o `~/Library/Application Support/SketchUp 20XX` en Mac).
3. La regla global `~/.gemini/config/rules/sketchup-muebles.md` y el archivo `~/.gemini/config/mcp_config.json` en Antigravity.
