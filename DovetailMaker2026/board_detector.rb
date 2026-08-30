# frozen_string_literal: true

module DovetailMaker2026
  # Describes the selected rectangular board end in the board's own entities.
  class BoardDetector
    BoardInfo = Struct.new(:instance, :face, :origin, :x_axis, :inward_axis,
                           :z_axis, :width, :actual_thickness, :path,
                           keyword_init: true)

    def self.validate_selection!(selection)
      raise ArgumentError, 'E001|請先選取一個群組或元件作為 Tail Board。' if selection.empty?
      raise ArgumentError, 'E002|請一次只選取一個板件。' unless selection.length == 1
      item = selection.first
      unless item.is_a?(Sketchup::Group) || item.is_a?(Sketchup::ComponentInstance)
        raise ArgumentError, 'E003|V1 僅支援群組或元件，請先將板材建立為 Group 或 Component。'
      end
      raise ArgumentError, 'E004|選取的板件已鎖定。' if item.locked?
      item
    end

    def self.detect(instance, face, thickness, path = nil)
      raise ArgumentError, 'E101|所選端面不屬於目前板件。' unless face && face.is_a?(Sketchup::Face)
      raise ArgumentError, 'E102|V1 只支援四邊矩形加工端面。' unless face.outer_loop.vertices.length == 4 && face.loops.length == 1

      vertices = face.outer_loop.vertices.map(&:position)
      edges = vertices.each_with_index.map { |point, i| point.distance(vertices[(i + 1) % 4]) }
      lengths = edges.select { |length| length > Settings::GEOMETRY_TOLERANCE }.uniq { |length| (length / Settings::GEOMETRY_TOLERANCE).round }
      raise ArgumentError, 'E102|無法辨識此端面的板厚與板寬方向。' unless lengths.length == 2
      thickness_length = lengths.min_by { |length| (length - thickness).abs }
      unless (thickness_length - thickness).abs <= [Settings::GEOMETRY_TOLERANCE * 10, thickness * 0.01].max
        raise ArgumentError, 'E103|所選端面尺寸與設定板厚不一致，請確認板厚或重新選擇加工端面。'
      end
      width_length = (lengths - [thickness_length]).first
      raise ArgumentError, 'E102|板寬必須大於板厚。' unless width_length > thickness_length + Settings::GEOMETRY_TOLERANCE

      # Choose an edge in the wide direction. x_axis points along this edge;
      # z_axis is the selected face's thickness direction.
      wide_index = edges.each_index.max_by { |i| edges[i] }
      origin = vertices[wide_index]
      x_axis = (vertices[(wide_index + 1) % 4] - origin).normalize
      # orient x so the other two vertices lie in +x; gives stable preview.
      # The previous perimeter edge is the adjacent short edge. Using it makes
      # z=0 and z=thickness land on the actual two broad faces, regardless of
      # the selected face winding.
      z_axis = (vertices[(wide_index - 1) % 4] - origin).normalize
      inward_axis = face.normal.reverse
      BoardInfo.new(instance: instance, face: face, origin: origin, x_axis: x_axis,
                    inward_axis: inward_axis, z_axis: z_axis, width: width_length,
                    actual_thickness: thickness_length, path: path)
    end

    # A rectangular board has three pairs of faces. The two faces with the
    # smallest area are its end faces (thickness × width). Choose the one
    # closest to the camera so selection alone is enough to start the tool.
    def self.auto_detect(instance, face_to_avoid = nil)
      end_faces = rectangular_end_faces(instance)
      end_faces.reject! { |face| face == face_to_avoid }

      transformation = instance.transformation
      camera_eye = Sketchup.active_model.active_view.camera.eye
      face = end_faces.min_by { |candidate| camera_eye.distance(candidate.bounds.center.transform(transformation)) }
      dimensions = face_dimensions(face)
      thickness = dimensions.min
      detect(instance, face, thickness)
    end

    # Select the board end closest to an existing joint in world coordinates.
    # Used for Pin Board so camera position cannot reverse the result.
    def self.auto_detect_near(instance, world_point, thickness)
      # Do not assume the end face is the smallest face. A wide, short board
      # has side faces smaller than its actual width x thickness joint face.
      # Every valid joint face has one edge equal to the board thickness; the
      # face nearest the completed Tail joint is the intended mating end.
      faces = rectangular_joint_faces(instance, thickness)
      transformation = instance.transformation
      face = faces.min_by do |candidate|
        world_point.distance(candidate.bounds.center.transform(transformation))
      end
      detect(instance, face, thickness)
    end

    def self.rectangular_joint_faces(instance, thickness)
      tolerance = [Settings::GEOMETRY_TOLERANCE * 10, thickness * 0.01].max
      faces = entities_for(instance).grep(Sketchup::Face).select do |face|
        next false unless face.outer_loop.vertices.length == 4 && face.loops.length == 1
        dimensions = face_dimensions(face)
        next false unless dimensions.length == 2
        dimensions.any? { |length| (length - thickness).abs <= tolerance } &&
          dimensions.max > thickness + Settings::GEOMETRY_TOLERANCE
      end
      raise ArgumentError, 'E005|找不到符合板厚的 Pin Board 加工端面。' if faces.empty?
      faces
    end

    def self.rectangular_end_faces(instance)
      faces = entities_for(instance).grep(Sketchup::Face).select do |face|
        face.outer_loop.vertices.length == 4 && face.loops.length == 1
      end
      raise ArgumentError, 'E005|選取的物件不是可辨識的矩形實體板。' if faces.length < 6
      minimum_area = faces.map(&:area).min
      tolerance = [minimum_area * 0.01, Settings::MIN_FACE_AREA].max
      result = faces.select { |face| (face.area - minimum_area).abs <= tolerance }
      raise ArgumentError, 'E005|無法自動辨識板材的兩個加工端面。' if result.empty?
      result
    end

    def self.face_dimensions(face)
      vertices = face.outer_loop.vertices.map(&:position)
      vertices.each_with_index.map { |point, index| point.distance(vertices[(index + 1) % vertices.length]) }
              .select { |length| length > Settings::GEOMETRY_TOLERANCE }
              .uniq { |length| (length / Settings::GEOMETRY_TOLERANCE).round }
    end

    # Find the geometric mate of the current end face. The opposite end must
    # have the same area, an opposite normal and the greatest separation.
    def self.opposite_end(instance, current_face, thickness)
      entities = entities_for(instance)
      area_tolerance = [current_face.area * 0.01, Settings::MIN_FACE_AREA].max
      candidates = entities.grep(Sketchup::Face).select do |face|
        next false if face == current_face
        next false unless face.outer_loop.vertices.length == 4 && face.loops.length == 1
        same_area = (face.area - current_face.area).abs <= area_tolerance
        opposite_normal = face.normal.dot(current_face.normal) < -0.999
        same_area && opposite_normal
      end
      raise ArgumentError, 'E006|找不到與目前端面配對的另一端。' if candidates.empty?

      current_center = current_face.bounds.center
      opposite = candidates.max_by { |face| current_center.distance(face.bounds.center) }
      detect(instance, opposite, thickness)
    end

    def self.entities_for(instance)
      instance.is_a?(Sketchup::Group) ? instance.entities : instance.definition.entities
    end
  end
end
