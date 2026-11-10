require 'sketchup'
require 'csv'

module Muebles
  # Catalogo oficial de colores de melamina MDF Navetta (https://navetta.mx/)
  # Formato: 'Nombre' => { rgb: [R, G, B], veta: true/false, categoria: :maderado/:solido/:especial }
  CATALOGO_NAVETTA = {
    # Linea Maderados (con veta)
    'Parota'           => { rgb: [158, 104,  64], veta: true,  categoria: :maderado },
    'Tzalam Natura'    => { rgb: [122,  75,  50], veta: true,  categoria: :maderado },
    'Nogal'            => { rgb: [110,  74,  52], veta: true,  categoria: :maderado },
    'Nogal Albura'     => { rgb: [135,  96,  68], veta: true,  categoria: :maderado },
    'Encino Americano' => { rgb: [204, 168, 125], veta: true,  categoria: :maderado },
    'Encino Europeo'   => { rgb: [192, 156, 116], veta: true,  categoria: :maderado },
    'Roble Blanco'     => { rgb: [226, 216, 202], veta: true,  categoria: :maderado },
    'Roble Cenizo'     => { rgb: [168, 158, 148], veta: true,  categoria: :maderado },
    'Fresno Natura'    => { rgb: [216, 192, 158], veta: true,  categoria: :maderado },
    'Avellana'         => { rgb: [162, 122,  88], veta: true,  categoria: :maderado },
    'Cedro'            => { rgb: [165,  92,  58], veta: true,  categoria: :maderado },
    'Duna'             => { rgb: [198, 178, 152], veta: true,  categoria: :maderado },
    'Fiorano'          => { rgb: [145, 118,  94], veta: true,  categoria: :maderado },
    'Lisboa'           => { rgb: [176, 145, 112], veta: true,  categoria: :maderado },
    'Lugo'             => { rgb: [152, 126,  98], veta: true,  categoria: :maderado },
    'Modena'           => { rgb: [132, 104,  82], veta: true,  categoria: :maderado },
    'Tabaco'           => { rgb: [ 92,  66,  50], veta: true,  categoria: :maderado },
    'Wengue'           => { rgb: [ 62,  46,  38], veta: true,  categoria: :maderado },
    # Linea Solidos / Unicolores (sin veta)
    'Blanco'           => { rgb: [245, 245, 242], veta: false, categoria: :solido },
    'Frosty'           => { rgb: [236, 238, 240], veta: false, categoria: :solido },
    'Polar'            => { rgb: [232, 235, 238], veta: false, categoria: :solido },
    'Marfil'           => { rgb: [238, 230, 214], veta: false, categoria: :solido },
    'Beige Sienna'     => { rgb: [212, 196, 174], veta: false, categoria: :solido },
    'Latte'            => { rgb: [198, 180, 158], veta: false, categoria: :solido },
    'Capuchino'        => { rgb: [168, 146, 126], veta: false, categoria: :solido },
    'Castana'          => { rgb: [138, 106,  82], veta: false, categoria: :solido },
    'Gris Claro'       => { rgb: [196, 198, 200], veta: false, categoria: :solido },
    'Gris Oxford'      => { rgb: [ 88,  92,  96], veta: false, categoria: :solido },
    'Azul Milano'      => { rgb: [ 66,  92, 118], veta: false, categoria: :solido },
    'Olivo'            => { rgb: [112, 122,  98], veta: false, categoria: :solido },
    'Negro'            => { rgb: [ 38,  38,  40], veta: false, categoria: :solido },
    # Linea Especiales / Texturas
    'Linoza'           => { rgb: [188, 180, 168], veta: true,  categoria: :especial },
    'Carrara'          => { rgb: [235, 235, 238], veta: true,  categoria: :especial },
    'Brecia'           => { rgb: [164, 156, 148], veta: true,  categoria: :especial }
  }.freeze

  class << self
    def ruta_lib
      __FILE__
    end

    def recargar
      load __FILE__
    end

    def preparar_modelo
      model = Sketchup.active_model
      uo = model.options['UnitsOptions']
      uo['LengthFormat'] = Length::Decimal
      uo['LengthUnit'] = Length::Millimeter
      uo['LengthPrecision'] = 1
      uo['SuppressUnitsDisplay'] = false
      model
    end

    def material(nombre, color_rgb = [242, 240, 235], con_veta: false, espesores: '5.5mm;12mm;15mm;18mm;25mm')
      model = Sketchup.active_model
      mat = model.materials[nombre] || model.materials.add(nombre)
      mat.color = Sketchup::Color.new(*color_rgb)
      if defined?(Ladb::OpenCutList::MaterialAttributes)
        attrs = Ladb::OpenCutList::MaterialAttributes.new(mat)
        attrs.type = Ladb::OpenCutList::MaterialAttributes::TYPE_SHEET_GOOD
        attrs.std_thicknesses = espesores
        attrs.std_sizes = '2400mmx1200mm'
        attrs.grained = con_veta
        attrs.edge_decremented = false
        attrs.write_to_attributes
      end
      mat
    end

    def material_navetta(color_key, espesor_mm = nil)
      info = CATALOGO_NAVETTA[color_key] || CATALOGO_NAVETTA['Roble Blanco']
      sufijo = espesor_mm ? " #{espesor_mm}mm" : ''
      mat = material("Navetta - #{color_key}#{sufijo}", info[:rgb], con_veta: info[:veta])
      tex_file = File.join('C:/Users/ggeta/.gemini/antigravity/scratch/sketchup-mcp/su_mcp/su_mcp/textures_navetta', "#{color_key.tr(' ', '_')}.png")
      if File.exist?(tex_file)
        mat.texture = tex_file
        mat.texture.size = [600.mm, 1200.mm]
      end
      mat
    end

    def cargar_catalogo_navetta(espesor_mm = nil)
      preparar_modelo
      CATALOGO_NAVETTA.keys.map { |k| material_navetta(k, espesor_mm) }
    end

    def definir_pieza(nombre_def, dx, dy, dz, mat, visible: nil)
      model = Sketchup.active_model
      existing = model.definitions[nombre_def]
      model.definitions.remove(existing) if existing
      defn = model.definitions.add(nombre_def)
      face = defn.entities.add_face(
        Geom::Point3d.new(0, 0, 0),
        Geom::Point3d.new(dx, 0, 0),
        Geom::Point3d.new(dx, dy, 0),
        Geom::Point3d.new(0, dy, 0)
      )
      face.reverse! if face.normal.z < 0
      face.pushpull(dz)
      defn.entities.grep(Sketchup::Face).each { |f| f.material = mat; f.back_material = mat }

      if defined?(Ladb::OpenCutList::DefinitionAttributes)
        es_visible = visible.nil? ? !!(nombre_def =~ /Lateral Casco|Cubierta|Tapa Superior|Tapa Frontal|Puerta|Vista|Costado Visible/i) : visible
        da = Ladb::OpenCutList::DefinitionAttributes.new(defn)
        da.ignore_grain_direction = !es_visible
        da.write_to_attributes
      end

      defn
    end

    def colocar(entities, defn, x, y, z, nombre_instancia, mat)
      inst = entities.add_instance(defn, Geom::Transformation.translation(Geom::Point3d.new(x, y, z)))
      inst.name = nombre_instancia
      inst.material = mat
      inst
    end

    def pieza(entities, nombre_def, dx, dy, dz, x, y, z, mat, nombre_instancia = nil)
      defn = definir_pieza(nombre_def, dx, dy, dz, mat)
      colocar(entities, defn, x, y, z, nombre_instancia || nombre_def, mat)
    end

    def cajon(ancho_caja:, prof_caja:, alto_caja:, espesor: 15.mm, prefijo: 'Cajon', entities: nil, ox: 0.mm, oy: 0.mm, oz: 0.mm, mat_caja: nil, mat_frente: nil, ancho_frente: nil, alto_frente: nil, fx: nil, fy: nil, fz: nil)
      model = preparar_modelo
      own_op = entities.nil?
      model.start_operation("Crear #{prefijo}", true) if own_op

      begin
        mat_caja ||= material("Melamina Blanca #{espesor.to_mm.round}mm", [242, 240, 235], con_veta: false)
        target_ents = entities || model.active_entities
        grp = target_ents.add_group
        grp.name = "#{prefijo} (#{ancho_caja.to_mm.round}x#{prof_caja.to_mm.round}x#{alto_caja.to_mm.round}mm)"
        ce = grp.entities

        ancho_int = ancho_caja - (2 * espesor)
        prof_int  = prof_caja - (2 * espesor)

        def_lat   = model.definitions["#{prefijo} - Lateral"] || definir_pieza("#{prefijo} - Lateral", espesor, prof_caja, alto_caja, mat_caja)
        def_ft    = model.definitions["#{prefijo} - Frente/Trasera Int"] || definir_pieza("#{prefijo} - Frente/Trasera Int", ancho_int, espesor, alto_caja, mat_caja)
        def_fondo = model.definitions["#{prefijo} - Fondo"] || definir_pieza("#{prefijo} - Fondo", ancho_int, prof_int, espesor, mat_caja)

        colocar(ce, def_lat, ox, oy, oz, 'Lateral Izq', mat_caja)
        colocar(ce, def_lat, ox + ancho_caja - espesor, oy, oz, 'Lateral Der', mat_caja)
        colocar(ce, def_ft, ox + espesor, oy, oz, 'Contra-frente', mat_caja)
        colocar(ce, def_ft, ox + espesor, oy + prof_caja - espesor, oz, 'Trasera', mat_caja)
        colocar(ce, def_fondo, ox + espesor, oy + espesor, oz, 'Fondo Cajón', mat_caja)

        if ancho_frente && alto_frente
          mat_frente ||= material('Melamina Roble 15mm', [196, 154, 108], con_veta: true)
          t_frente = 15.mm
          def_frente = model.definitions["#{prefijo} - Tapa Frontal"] || definir_pieza("#{prefijo} - Tapa Frontal", ancho_frente, t_frente, alto_frente, mat_frente)
          colocar(ce, def_frente, fx || ox, fy || (oy - t_frente), fz || oz, 'Tapa Frontal Exterior', mat_frente)
        end

        if own_op
          model.commit_operation
          model.active_view.zoom(grp)
        end
        grp
      rescue => e
        model.abort_operation if own_op
        raise e
      end
    end

    def cajonera(ancho:, prof:, alto:, niveles: 3, columnas: 1, espesor_casco: 15.mm, espesor_cajon: 15.mm, alto_zocalo: 80.mm, prof_cajon: nil, alto_cajon: nil, ox: 0.mm, oy: 0.mm, oz: 0.mm, prefijo: 'Mueble')
      model = preparar_modelo
      model.start_operation("Crear #{prefijo}", true)

      begin
        t = espesor_casco
        tc = espesor_cajon
        mat_casco  = material("Melamina Blanca #{t.to_mm.round}mm", [242, 240, 235], con_veta: false)
        mat_cajon  = (tc == t) ? mat_casco : material("Melamina Blanca #{tc.to_mm.round}mm", [235, 235, 230], con_veta: false)
        mat_frente = material("Melamina Roble #{t.to_mm.round}mm", [196, 154, 108], con_veta: true)

        alto_lateral  = alto - t
        ancho_int     = ancho - (2 * t)
        ancho_amarre  = 100.mm
        alto_vano     = alto_lateral - alto_zocalo - (2 * t)
        ancho_vano_col = (ancho_int - ((columnas - 1) * t)) / columnas.to_f

        grp = model.active_entities.add_group
        grp.name = "#{prefijo} (#{ancho.to_mm.round}x#{prof.to_mm.round}x#{alto.to_mm.round}mm)"
        ents = grp.entities

        casco_grp = ents.add_group
        casco_grp.name = 'Casco'
        ce_casco = casco_grp.entities

        def_lat = definir_pieza("#{prefijo} - Lateral Casco", t, prof, alto_lateral, mat_casco)
        colocar(ce_casco, def_lat, ox, oy, oz, 'Lateral Izquierdo', mat_casco)
        colocar(ce_casco, def_lat, ox + ancho - t, oy, oz, 'Lateral Derecho', mat_casco)

        def_piso = definir_pieza("#{prefijo} - Piso Inferior", ancho_int, prof, t, mat_casco)
        colocar(ce_casco, def_piso, ox + t, oy, oz + alto_zocalo, 'Piso Inferior', mat_casco)

        if alto_zocalo >= 70.mm
          def_zoc = definir_pieza("#{prefijo} - Zocalo", ancho_int, t, alto_zocalo, mat_casco)
          colocar(ce_casco, def_zoc, ox + t, oy + 15.mm, oz, 'Zócalo Frontal', mat_casco)
          colocar(ce_casco, def_zoc, ox + t, oy + prof - 30.mm, oz, 'Zócalo Trasero', mat_casco)
        end

        def_amarre = definir_pieza("#{prefijo} - Amarre Superior", ancho_int, ancho_amarre, t, mat_casco)
        colocar(ce_casco, def_amarre, ox + t, oy, oz + alto_lateral - t, 'Amarre Frontal', mat_casco)
        colocar(ce_casco, def_amarre, ox + t, oy + prof - ancho_amarre, oz + alto_lateral - t, 'Amarre Trasero', mat_casco)

        def_fondo = definir_pieza("#{prefijo} - Fondo Casco", ancho_int, t, alto_vano, mat_casco)
        colocar(ce_casco, def_fondo, ox + t, oy + prof - t, oz + alto_zocalo + t, 'Fondo Trasero', mat_casco)

        if columnas > 1
          def_div = definir_pieza("#{prefijo} - Divisoria Central", t, prof - t, alto_vano, mat_casco)
          def_zoc_ref = (alto_zocalo >= 70.mm) ? definir_pieza("#{prefijo} - Zocalo Refuerzo", t, prof - 60.mm, alto_zocalo, mat_casco) : nil
          (columnas - 1).times do |c|
            x_div = ox + t + ((c + 1) * ancho_vano_col) + (c * t)
            colocar(ce_casco, def_div, x_div, oy, oz + alto_zocalo + t, "Divisoria #{c + 1}", mat_casco)
            colocar(ce_casco, def_zoc_ref, x_div, oy + 30.mm, oz, "Refuerzo Zócalo #{c + 1}", mat_casco) if def_zoc_ref
          end
        end

        def_tapa = definir_pieza("#{prefijo} - Tapa Superior", ancho, prof + t + 3.mm, t, mat_frente)
        colocar(ce_casco, def_tapa, ox, oy - t - 3.mm, oz + alto_lateral, 'Tapa Superior', mat_frente)

        luz_corredera = 13.mm
        ancho_caja    = ancho_vano_col - (2 * luz_corredera)
        p_caja        = prof_cajon || (prof - 40.mm)
        calle_h       = 4.mm
        alto_disp_fr  = alto_lateral - alto_zocalo - 6.mm
        alto_frente   = (alto_disp_fr - ((niveles - 1) * calle_h)) / niveles.to_f
        h_caja        = alto_cajon || [alto_frente - 35.mm, 80.mm].max
        ancho_frente  = (ancho - 4.mm - ((columnas - 1) * 4.mm)) / columnas.to_f

        def_c_lat    = definir_pieza("#{prefijo} - Cajon Lateral", tc, p_caja, h_caja, mat_cajon)
        def_c_ft     = definir_pieza("#{prefijo} - Cajon Frente/Trasera Int", ancho_caja - (2 * tc), tc, h_caja, mat_cajon)
        def_c_fondo  = definir_pieza("#{prefijo} - Cajon Fondo", ancho_caja - (2 * tc), p_caja - (2 * tc), tc, mat_cajon)
        def_c_frente = definir_pieza("#{prefijo} - Cajon Tapa Frontal", ancho_frente, t, alto_frente, mat_frente)

        columnas.times do |col|
          x_vano   = ox + t + (col * (ancho_vano_col + t))
          x_frente = ox + 2.mm + (col * (ancho_frente + 4.mm))

          niveles.times do |fila|
            apertura_y = (col == 0 && fila == niveles - 1) ? -170.mm : 0.mm
            z_frente   = oz + alto_zocalo + 3.mm + (fila * (alto_frente + calle_h))
            z_caja     = z_frente + 15.mm
            x_caja     = x_vano + luz_corredera
            y_caja     = oy + 12.mm + apertura_y

            sub = ents.add_group
            sub.name = "Cajón C#{col + 1}-N#{fila + 1}"
            ce = sub.entities
            colocar(ce, def_c_lat, x_caja, y_caja, z_caja, 'Lateral Izq', mat_cajon)
            colocar(ce, def_c_lat, x_caja + ancho_caja - tc, y_caja, z_caja, 'Lateral Der', mat_cajon)
            colocar(ce, def_c_ft, x_caja + tc, y_caja, z_caja, 'Contra-frente', mat_cajon)
            colocar(ce, def_c_ft, x_caja + tc, y_caja + p_caja - tc, z_caja, 'Trasera', mat_cajon)
            colocar(ce, def_c_fondo, x_caja + tc, y_caja + tc, z_caja, 'Fondo Cajón', mat_cajon)
            colocar(ce, def_c_frente, x_frente, oy - t + apertura_y, z_frente, 'Tapa Frontal', mat_frente)
          end
        end

        model.commit_operation
        model.active_view.zoom(grp)
        grp
      rescue => e
        model.abort_operation
        raise e
      end
    end

    # Exporta directamente desde OpenCutList al formato de 10 columnas del proveedor (en 0 tokens)
    def exportar_pedido(ruta_csv = nil)
      preparar_modelo
      ruta_csv ||= File.join(ENV['USERPROFILE'] || Dir.home, 'Desktop', 'pedido_proveedor.csv')
      worker = Ladb::OpenCutList::CutlistGenerateWorker.new
      cutlist = worker.run

      CSV.open(ruta_csv, 'w', write_headers: true, headers: [
        'Cantidad', 'Largo', 'Ancho', 'bisagra (BSG+ lado)',
        'cubre canto Largo 1', 'cubre canto Largo 2', 'cubre canto Ancho 1', 'cubre canto Ancho 2',
        'Material tablero', 'Descripción'
      ]) do |csv|
        cutlist.groups.each do |g|
          next unless g.material_type == Ladb::OpenCutList::MaterialAttributes::TYPE_SHEET_GOOD
          next if g.material_name =~ /^Existente/i
          mat_clean = g.material_name.sub(/\s*\d+\s*mm$/i, '').strip
          g.parts.each do |p|
            largo = p.length.to_f.round(1)
            ancho = p.width.to_f.round(1)
            largo = largo.to_i if largo == largo.to_i
            ancho = ancho.to_i if ancho == ancho.to_i
             puede_canto = (largo >= 70 && ancho >= 70)
            c_l1 = ''; c_l2 = ''; c_a1 = ''; c_a2 = ''
            if puede_canto
              if p.name =~ /Tapa|Puerta/i
                c_l1 = c_l2 = c_a1 = c_a2 = mat_clean
              elsif p.name =~ /Lateral|Piso|Divisoria|Entrepano|Amarre|Frente\/Trasera/i
                c_l1 = mat_clean
              end
            end
            csv << [p.count, largo, ancho, '', c_l1, c_l2, c_a1, c_a2, g.material_name, p.name]
          end
        end
      end
      ruta_csv
    end
  end
end
