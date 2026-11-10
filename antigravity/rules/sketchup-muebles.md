---
trigger: model_decision
description: Mandatory rules for melamine/woodworking furniture design, OpenCutList integration, and 3D modeling in SketchUp via MCP (eval_ruby).
---

# Furniture Design & SketchUp Modeling Rules (`Muebles` + OpenCutList)

## 1. Native `Muebles` Ruby Library in SketchUp (Token Optimization - Windows & macOS)
SketchUp automatically loads `muebles_lib.rb` on startup. Use this 3-tier hierarchy when calling `eval_ruby`:
1. **Tier 1 (1-line calls for standard furniture)**:
   - Single Drawer: `Muebles.cajon(ancho_caja: 524.mm, prof_caja: 500.mm, alto_caja: 195.mm, espesor: 12.mm, ox: 0.mm, prefijo: 'Cajon')`
   - Chest of Drawers / Dresser / Nightstand: `Muebles.cajonera(ancho: 800.mm, prof: 450.mm, alto: 900.mm, niveles: 4, columnas: 1, espesor_casco: 15.mm, espesor_cajon: 15.mm, alto_zocalo: 80.mm, ox: 0.mm, prefijo: 'Comoda')`
   - Export 10-column supplier order table (0 tokens, saves to `~/Desktop/pedido_proveedor.csv` by default): `Muebles.exportar_pedido`
2. **Tier 2 (Custom designs without limits)**: If the furniture is not a standard chest of drawers (closets, kitchens, desks, wall cabinets), build it freely in `eval_ruby` using the `Muebles` building blocks: `Muebles.preparar_modelo`, `Muebles.material(name, rgb, con_veta:)`, `Muebles.definir_pieza(name, dx, dy, dz, mat)` (reuse for identical parts), `Muebles.colocar(ents, defn, x, y, z, inst_name, mat)`, `Muebles.pieza(...)`, and `Muebles.cajon(...)`.
3. **Tier 3 (Evolutionary Multi-Platform Library)**: Query the active library file path in SketchUp with `Muebles.ruta_lib`. If you create a reusable furniture generator in `muebles_lib.rb`, sync it to the repository and reload it live with `Muebles.recargar` via `eval_ruby`.

## 2. Grouping Hierarchy (For Moving in 3D View) & OpenCutList
- **Mandatory Hierarchical Grouping (`Sketchup::Group`)**:
  - **Multi-cabinet projects (Kitchens, Closets, Media Centers)**: Project Root Group $\rightarrow$ **1 Group per individual Cabinet/Module** (so each cabinet can be moved independently).
  - **Inside each Furniture/Cabinet**: Always group the entire unit in a main `Group` containing:
    1. Subgroup **`Casco`** (sides, bottom, top/stretchers, dividers, back panel, toe kicks, countertop).
    2. An independent Subgroup for each **`Cajón N`** containing **both the drawer box and its outer front face together**, allowing the entire drawer to slide/move as a single object.
    3. Subgroups for additional movable elements (doors, pull-out trays).
- **Units & Parts for OpenCutList**: Always use `.mm` in Ruby and set model units to `mm`. Inside groups, **every individual board** must be a `ComponentInstance` (`ComponentDefinition` built from `[0,0,0]`) with material assigned; OpenCutList ignores `Group` containers and lists all nested boards regardless of grouping depth.
- **Usable Board Size & Navetta Materials (`https://navetta.mx/`)**: Board size `2400 × 1200 mm` (`TYPE_SHEET_GOOD`, thicknesses `5.5mm;12mm;15mm;18mm;25mm`, `edge_decremented = false`). Use `Muebles.material_navetta('<Color>')` or `Muebles.cargar_catalogo_navetta`:
  - *Woodgrains (`veta: true`):* `Parota`, `Tzalam Natura`, `Nogal`, `Nogal Albura`, `Encino Americano`, `Encino Europeo`, `Roble Blanco`, `Roble Cenizo`, `Fresno Natura`, `Avellana`, `Cedro`, `Duna`, `Fiorano`, `Lisboa`, `Lugo`, `Modena`, `Tabaco`, `Wengue`.
  - *Solids (`veta: false`):* `Blanco`, `Frosty`, `Polar`, `Marfil`, `Beige Sienna`, `Latte`, `Capuchino`, `Castana`, `Gris Claro`, `Gris Oxford`, `Azul Milano`, `Olivo`, `Negro`.
  - *Specials (`veta: true`):* `Linoza`, `Carrara`, `Brecia`.
  - *Per-Part Grain Optimization (`ignore_grain_direction`):* On woodgrain materials (`veta: true`), **only visible exterior parts** (`Lateral Casco`, `Cubierta / Tapa Superior`, `Tapa Frontal`, `Puerta`) lock grain direction (`ignore_grain_direction = false`). All **internal/hidden parts** (`Piso`, `Fondo`, `Zócalo`, `Amarre`, `Cajas de cajón`, `Refuerzos`) set `ignore_grain_direction = true` so they can rotate `90°` to maximize sheet yield.
  - *Reused parts:* Prefix `Existente - ...` on material and definition to exclude them from purchase and `exportar_pedido`. Hardware uses `TYPE_HARDWARE`.
- **Supplier Fabrication Minimums**: Minimum cut size in melamine is **`50.mm`** (`100.mm` in plywood). Minimum size for parts with edge banding: **`70.mm`** (always use `>= 80.mm` on toe kicks and stretchers).
- **Supplier Order Table (10 columns)**: `Cantidad | Largo | Ancho | bisagra (BSG+ lado) | cubre canto Largo 1 | cubre canto Largo 2 | cubre canto Ancho 1 | cubre canto Ancho 2 | Material tablero | Descripción`.

## 3. Melamine Construction Standards
- **Base thickness**: `15.mm` by default (`12.mm` or `18.mm` if requested).
- **Base Structure**: *Standard floor furniture:* Toe kick `70-80.mm` (`80.mm`), recessed `15.mm` in front + cross support under vertical dividers. *Floating/legs:* Omit toe kick; full bottom panel bears weight.
- **Top Structure**: *Base cabinets:* 2 flat top stretchers `80-100.mm` (front and rear) + top cover overhanging sides with a `2-5.mm` front overhang. If using recessed connectors (e.g., FinityPro), keep both stretchers, place connector in front of rear stretcher (`>= 15.mm` clearance), and leave `50-60.mm` upper clearance. *Tall/wall cabinets:* Full-height side panels and solid internal top panel.
- **Structural Support**: Spans `> 900.mm` or `2+` drawer columns require a central vertical divider (`t`) and base support.
- **Drawers & Anti-Collision**: Telescopic slide clearance **`13.mm` per side** (`ancho_caja = ancho_vano - 26.mm`). Inner front/back between drawer sides. Vertical clearance between boxes `15-20.mm` and rear clearance `10-15.mm`. **Mandatory Box–Front Alignment:** the bottom of each drawer box must sit **`>= 6.mm` above the bottom edge of its own front face** ($Z_{\text{caja}} \ge Z_{\text{frente}} + 6.\text{mm}$) so it never collides with the lower front panel when opening.
- **Fronts**: *Overlay (default):* `2.mm` outer perimeter gap, `3.5-4.mm` gap between adjacent fronts. *Inset:* `3.mm` perimeter gap. Leave 1 top drawer/door slightly open (`-170.mm` in Y) for visual inspection.
- **User Response (Token Saving)**: Keep chat responses **very brief and direct** (only confirm creation and overall dimensions). **DO NOT print cutlist tables in the chat** unless explicitly requested.
- **Missing Rule Alert**: If you detect an undefined construction detail or hardware constraint, highlight it at the end of your reply:
  > 🚨 🛠️ **ALERTA DE REGLA FALTANTE / MISSING RULE ALERT:** *[1-line explanation and concrete proposal]*
