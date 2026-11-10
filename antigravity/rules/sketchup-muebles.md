---
trigger: model_decision
description: Reglas obligatorias para diseño de muebles en melamina/madera, OpenCutList y modelado en SketchUp mediante MCP (eval_ruby).
---

# Reglas de Diseño de Muebles y SketchUp (`Muebles` + OpenCutList)

## 1. Librería Nativa `Muebles` en SketchUp (Ahorro de Tokens - Windows y macOS)
SketchUp carga automáticamente `muebles_lib.rb` al iniciar. En `eval_ruby` usa esta jerarquía:
1. **Nivel 1 (1 línea para muebles estándar)**:
   - Cajón: `Muebles.cajon(ancho_caja: 524.mm, prof_caja: 500.mm, alto_caja: 195.mm, espesor: 12.mm, ox: 0.mm, prefijo: 'Cajon')`
   - Cajonera/Cómoda/Buró: `Muebles.cajonera(ancho: 800.mm, prof: 450.mm, alto: 900.mm, niveles: 4, columnas: 1, espesor_casco: 15.mm, espesor_cajon: 15.mm, alto_zocalo: 80.mm, ox: 0.mm, prefijo: 'Comoda')`
   - Exportar tabla de 10 columnas del proveedor (0 tokens, guarda en `~/Desktop/pedido_proveedor.csv` por defecto): `Muebles.exportar_pedido`
2. **Nivel 2 (Diseños personalizados sin límites)**: Si el mueble no es una cajonera estándar (clóset, cocina, escritorio, alacena), constrúyelo libremente en `eval_ruby` usando los bloques de `Muebles`: `Muebles.preparar_modelo`, `Muebles.material(nombre, rgb, con_veta:)`, `Muebles.definir_pieza(nombre, dx, dy, dz, mat)` (reutilizar para piezas idénticas), `Muebles.colocar(ents, defn, x, y, z, inst_name, mat)`, `Muebles.pieza(...)` y `Muebles.cajon(...)`.
3. **Nivel 3 (Librería Evolutiva Multiplataforma)**: Puedes consultar la ruta activa del archivo en SketchUp con `Muebles.ruta_lib`. Si agregas un nuevo tipo de mueble reutilizable a `muebles_lib.rb`, sincronízalo en el repositorio y recárgalo en vivo con `Muebles.recargar` desde `eval_ruby`.

## 2. Jerarquía de Agrupación (Para Mover en Visualización) y OpenCutList
- **Agrupación jerárquica obligatoria (`Sketchup::Group`)**:
  - **Proyectos multipieza (Cocinas, Clósets, Centros de TV)**: Grupo raíz del proyecto $\rightarrow$ **1 Grupo por cada Gabinete/Módulo individual** (para poder mover cada gabinete por separado).
  - **Dentro de cada Mueble/Gabinete**: Agrupar siempre el mueble completo en un `Group` principal que contenga:
    1. Subgrupo **`Casco`** (laterales, piso, techo/amarres, divisoria, fondo, zócalos, cubierta).
    2. Un Subgrupo independiente por cada **`Cajón N`** que incluya **tanto la caja del cajón como su tapa frontal exterior juntas**, para poder deslizar/mover el cajón completo como un solo objeto.
    3. Subgrupos para elementos móviles adicionales (puertas, charolas corredizas).
- **Unidades y Piezas para OpenCutList**: Siempre `.mm` en Ruby y modelo en `mm`. Dentro de los grupos, **cada tabla individual** debe ser un `ComponentInstance` (`ComponentDefinition` desde `[0,0,0]`) con material asignado; OpenCutList ignora los contenedores `Group` y despieza todas las tablas internas sin importar cuántos niveles de grupos existan.
- **Placa útil y Materiales Navetta (`https://navetta.mx/`)**: Placa `2400 × 1200 mm` (`TYPE_SHEET_GOOD`, espesores `5.5mm;12mm;15mm;18mm;25mm`, `edge_decremented = false`). Usa `Muebles.material_navetta('<Color>')` o `Muebles.cargar_catalogo_navetta`:
  - *Maderados (`veta: true`):* `Parota`, `Tzalam Natura`, `Nogal`, `Nogal Albura`, `Encino Americano`, `Encino Europeo`, `Roble Blanco`, `Roble Cenizo`, `Fresno Natura`, `Avellana`, `Cedro`, `Duna`, `Fiorano`, `Lisboa`, `Lugo`, `Modena`, `Tabaco`, `Wengue`.
  - *Sólidos (`veta: false`):* `Blanco`, `Frosty`, `Polar`, `Marfil`, `Beige Sienna`, `Latte`, `Capuchino`, `Castana`, `Gris Claro`, `Gris Oxford`, `Azul Milano`, `Olivo`, `Negro`.
  - *Especiales (`veta: true`):* `Linoza`, `Carrara`, `Brecia`.
  - *Optimización de Veta por Pieza (`ignore_grain_direction`):* En materiales con veta (`veta: true`), **solo las piezas exteriores visibles** (`Lateral Casco`, `Cubierta / Tapa Superior`, `Tapa Frontal`, `Puerta`) mantienen la dirección de veta bloqueada (`ignore_grain_direction = false`). Todas las **piezas internas/ocultas** (`Piso`, `Fondo`, `Zócalo`, `Amarre`, `Cajas de cajón`, `Refuerzos`) llevan `ignore_grain_direction = true` para permitir rotarlas `90°` y maximizar el aprovechamiento de la hoja. En colores sólidos (`veta: false`), todas las piezas pueden rotarse libremente.
  - *Piezas reutilizadas:* Prefijo `Existente - ...` en material y definición para excluirlas de compra y `exportar_pedido`. Herrajes como `TYPE_HARDWARE`.
- **Mínimos de fabricación**: Corte mínimo en melamina **`50.mm`** (`100.mm` en triplay). Mínimo para piezas con cubrecanto: **`70.mm`** (usar `>= 80.mm` en zócalos y amarres).
- **Tabla de Pedido (10 columnas)**: `Cantidad | Largo | Ancho | bisagra (BSG+ lado) | cubre canto Largo 1 | cubre canto Largo 2 | cubre canto Ancho 1 | cubre canto Ancho 2 | Material tablero | Descripción`.

## 3. Estándares Constructivos en Melamina
- **Espesor base**: `15.mm` por defecto (`12.mm` o `18.mm` si se solicita).
- **Base**: *Piso estándar:* Zócalo `70-80.mm` (`80.mm`), remetido `15.mm` al frente + refuerzo bajo divisorias. *Flotante/patas:* Sin zócalo; piso corrido.
- **Coronación**: *Muebles bajos:* 2 amarres superiores acostados `80-100.mm` (frontal y trasero) + tapa pasante con vuelo frontal de `2-5.mm`. Si lleva conector empotrado (ej. FinityPro), conservar ambos amarres, ubicar el conector delante del amarre trasero (`>= 15.mm` libre) y dejar cámara libre superior de `50-60.mm`. *Muebles altos:* Laterales pasantes y techo sólido interno.
- **Soporte**: Claros `> 900.mm` o `2+` columnas llevan divisoria vertical central (`t`) y refuerzo en base.
- **Cajones y Anti-Colisión**: Descuento de corredera telescópica **`13.mm` por lado** (`ancho_caja = ancho_vano - 26.mm`). Contrafrente y trasera internos entre laterales. Holgura vertical entre cajas `15-20.mm` y trasera `10-15.mm`. **Alineación obligatoria Caja–Frente:** el piso de cada caja debe ir **`>= 6.mm` por encima del borde inferior de su propia tapa frontal** ($Z_{\text{caja}} \ge Z_{\text{frente}} + 6.\text{mm}$) para no chocar con la tapa inferior al abrirse.
- **Frentes**: *Superpuestos (por defecto):* `2.mm` luz exterior, `3.5-4.mm` calle entre frentes. *Empotrados (inset):* `3.mm` luz perimetral. Dejar 1 cajón/puerta superior entreabierto (`-170.mm` en Y).
- **Respuesta (Ahorro de tokens)**: Muy breve (solo confirmar creación y medidas). **NO incluir tabla de despiece en el chat** salvo que el usuario la pida.
- **Alerta de Regla Faltante**: Si detectas un criterio o herraje no definido en esta regla, avisa al final con:
  > 🚨 🛠️ **ALERTA DE REGLA FALTANTE:** *[Explicación de 1 línea y propuesta]*
