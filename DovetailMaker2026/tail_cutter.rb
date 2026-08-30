# frozen_string_literal: true

module DovetailMaker2026
  class TailCutter
    def self.cut(board, result)
      model = Sketchup.active_model
      model.start_operation('Create Dovetail Tails', true)
      begin
        make_unique(board.instance)
        # make_unique changes a component definition but does not invalidate
        # local face coordinates. Groups are already unique containers.
        entities = BoardDetector.entities_for(board.instance)
        result.wastes.each do |waste|
          cut_waste(entities, board, waste, board.actual_thickness)
        end
        # Attribute dictionaries persist primitive values reliably across SKP
        # saves. JSON also keeps this data independent of Ruby object lifetime.
        board.instance.set_attribute(Settings::DICTIONARY, 'tail_layout', JSON.generate(serialize(board, result)))
        board.instance.set_attribute(Settings::DICTIONARY, 'phase', 'tails_complete')
        model.commit_operation
      rescue StandardError
        model.abort_operation
        raise
      end
    end

    def self.make_unique(instance)
      instance.make_unique if instance.respond_to?(:make_unique)
    end

    def self.cut_waste(entities, board, polygon, board_thickness)
      # Draw the trapezoid on one broad face, then push it through the board.
      # SketchUp splits the existing face and leaves the rectangular board solid
      # with the waste prism removed.
      top_points = polygon.map { |x, y| point(board, x, y, board_thickness) }
      face = entities.add_face(top_points)
      raise RuntimeError, 'E301|無法建立 Tail 廢料輪廓。請確認板件為封閉矩形實體。' unless face
      direction = face.normal.dot(board.z_axis) > 0.0 ? -board_thickness : board_thickness
      face.pushpull(direction, false)
    end

    def self.point(board, x, y, z)
      board.origin.offset(board.x_axis, x).offset(board.inward_axis, y).offset(board.z_axis, z)
    end

    def self.serialize(board, result)
      {
        'version' => 1,
        'width' => result.width.to_f, 'thickness' => result.thickness.to_f,
        'tails' => result.tails.map do |tail|
          (tail['polygon'] || tail[:polygon]).map { |x, y| [x.to_f, y.to_f] }
        end,
        # Tail profile is stored in world-like local geometry only after cutting;
        # pin_cutter projects this authoritative outline rather than recalculating.
        'origin' => board.origin.to_a.map(&:to_f),
        'x_axis' => board.x_axis.to_a.map(&:to_f),
        'inward_axis' => board.inward_axis.to_a.map(&:to_f),
        'z_axis' => board.z_axis.to_a.map(&:to_f),
        'transformation' => board.instance.transformation.to_a.map(&:to_f)
      }
    end
  end
end
