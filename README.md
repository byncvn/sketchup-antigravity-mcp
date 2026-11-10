# SketchUp MCP + `Muebles` Library for Antigravity (Windows & macOS)

Optimized integration between **SketchUp (2024/2025/2026)**, **OpenCutList**, and **Antigravity** via the Model Context Protocol (MCP), engineered for parametric melamine/woodworking furniture design while saving up to **90% of tokens**.

## Key Features
* **Silent Auto-Start in SketchUp:** The local TCP server (`127.0.0.1:9876`) starts automatically when SketchUp launches without popping open the Ruby Console window.
* **Native `Muebles` Ruby Library (`muebles_lib.rb`):**
  * **Level 1 (1-Line Shortcuts):** `Muebles.cajon(...)`, `Muebles.cajonera(...)` with automatic calculation for telescopic slides (`13 mm` clearance per side), toe kicks (`80 mm`), top stretchers (`100 mm`), and vertical dividers.
  * **Level 2 (Custom Building Blocks):** `Muebles.definir_pieza`, `Muebles.colocar`, `Muebles.pieza` to build custom kitchens, closets, desks, or cabinets without restrictions.
  * **Hierarchical Grouping Ready for Visualization:** Automatically groups by Cabinet $\rightarrow$ `Casco` (shell) + `Cajón N` (drawer box + front panel grouped together so you can slide or move each drawer with a single click).
  * **Native OpenCutList Integration:** Automatically configures materials as `Sheet Good` with `2400 × 1200 mm` usable board dimensions, `mm` model units, Navetta melamine catalog & textures, and smart grain direction (`ignore_grain_direction` on hidden internal parts to optimize sheet yield).
  * **Zero-Token Supplier Order Exporter:** `Muebles.exportar_pedido` exports the 10-column supplier `.csv` directly to your Desktop with automatic edge-banding rules (`Largo 1`, `Largo 2`, `Ancho 1`, `Ancho 2`).

---

## 1-Click Installation

### Windows (PowerShell)
```powershell
git clone https://github.com/byncvn/sketchup-antigravity-mcp.git sketchup-mcp
cd sketchup-mcp
.\install.ps1
```

### macOS (Terminal)
```bash
git clone https://github.com/byncvn/sketchup-antigravity-mcp.git sketchup-mcp
cd sketchup-mcp
chmod +x install.sh
./install.sh
```

Both installers automatically configure:
1. The isolated `.venv` virtual environment and Python MCP server (`mcp[cli]>=1.3.0,<2.0.0`).
2. The SketchUp Ruby plugin (`su_mcp.rb` + `su_mcp/main.rb` + `su_mcp/muebles_lib.rb` + `textures_navetta/`) across all installed SketchUp versions (`%APPDATA%\SketchUp` on Windows or `~/Library/Application Support/SketchUp 20XX` on macOS).
3. The global Antigravity rule (`~/.gemini/config/rules/sketchup-muebles.md`) and MCP server entry (`~/.gemini/config/mcp_config.json`).
