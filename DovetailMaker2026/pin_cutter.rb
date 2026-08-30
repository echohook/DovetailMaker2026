# frozen_string_literal: true

module DovetailMaker2026
  # V1 uses the profiles saved from the completed Tail cut. This deliberately
  # does not call GeometryCalculator: one source of truth is carried forward.
  class PinCutter
    def self.read_tail_layout(instance)
      raw = instance.get_attribute(Settings::DICTIONARY, 'tail_layout')
      raw = JSON.parse(raw) if raw.is_a?(String)
      raise ArgumentError, 'E401|找不到已完成的 Tail 資料，請先建立 Tail。' unless raw.is_a?(Hash)
      raw
    end

    def self.preview_polygons(pin_board, tail_layout)
      # Project authoritative Tail corner points into the selected Pin end plane.
      tail_layout.fetch('tails').map do |tail|
        tail.map do |x, y|
          world = tail_point(tail_layout, x, y, 0.0)
          project_to_plane(world, pin_board.origin.transform(pin_board.instance.transformation), pin_board.inward_axis.transform(pin_board.instance.transformation))
        end
      end
    end

    def self.cut(pin_board, tail_layout)
      model = Sketchup.active_model
      model.start_operation('Create Dovetail Pins', true)
      begin
        TailCutter.make_unique(pin_board.instance)
        entities = BoardDetector.entities_for(pin_board.instance)
        polygons = preview_polygons(pin_board, tail_layout)
        polygons.each do |world_polygon|
          cut_pin_pocket(entities, pin_board, world_polygon, number(tail_layout.fetch('thickness')))
        end
        pin_board.instance.set_attribute(Settings::DICTIONARY, 'phase', 'pins_complete')
        model.commit_operation
      rescue StandardError
        model.abort_operation
        raise
      end
    end

    def self.tail_point(layout, x, y, z)
      origin = Geom::Point3d.new(numeric_array(layout.fetch('origin')))
      local = origin.offset(Geom::Vector3d.new(numeric_array(layout.fetch('x_axis'))), number(x))
            .offset(Geom::Vector3d.new(numeric_array(layout.fetch('inward_axis'))), number(y))
            .offset(Geom::Vector3d.new(numeric_array(layout.fetch('z_axis'))), number(z))
      local.transform(Geom::Transformation.new(numeric_array(layout.fetch('transformation'))))
    end

    def self.project_to_plane(point, plane_origin, normal)
      plane = [plane_origin, normal]
      point.project_to_plane(plane)
    end

    def self.local_xy(board, point)
      local = point.transform(board.instance.transformation.inverse)
      delta = local - board.origin
      [delta.dot(board.x_axis), delta.dot(board.inward_axis)]
    end

    # Pin waste starts on its selected end face (x-z plane) and cuts along the
    # board's inward/length direction. This is intentionally different from a
    # Tail waste, which is drawn on a broad face and extruded through thickness.
    def self.cut_pin_pocket(entities, board, world_polygon, depth)
      inverse = board.instance.transformation.inverse
      local_points = sanitize_polygon(world_polygon.map { |point| point.transform(inverse) })
      face = entities.add_face(local_points)
      raise RuntimeError, 'E403|無法在 Pin Board 端面建立互補切削輪廓。' unless face
      direction = face.normal.dot(board.inward_axis) > 0.0 ? depth : -depth
      face.pushpull(direction, false)
    end

    def self.sanitize_polygon(points)
      tolerance = Settings::GEOMETRY_TOLERANCE * 10
      unique = []
      points.each do |point|
        unique << point unless unique.any? { |existing| existing.distance(point) <= tolerance }
      end
      if unique.length < 3
        raise ArgumentError, 'E404|Pin 加工端面方向錯誤，投影輪廓已重疊；請重新選取另一塊板材。'
      end
      unique
    end

    # V1.1.1 and earlier could persist SketchUp Length values as JSON strings.
    # Coerce both old string data and new numeric data before geometry calls.
    def self.numeric_array(values)
      values.map { |value| number(value) }
    end

    def self.number(value)
      return value.to_f if value.is_a?(Numeric)
      Float(value.to_s)
    rescue ArgumentError, TypeError
      parsed = Sketchup.parse_length(value.to_s)
      raise ArgumentError, 'E402|Tail 幾何資料包含無法辨識的尺寸。' unless parsed
      parsed.to_f
    end
  end
end
