# frozen_string_literal: true

module DovetailMaker2026
  # Selects one end face and draws all temporary preview graphics. Nothing in
  # this class creates model geometry.
  class DovetailTool
    def initialize(controller, phase)
      @controller = controller
      @phase = phase
      @hover_face = nil
      @hover_path = nil
    end

    def activate
      Sketchup.set_status_text(@phase == :tail ? '已自動選擇 Tail Board 端面；請在對話框輸入參數。' : '直接點選另一塊 Pin Board 的對應矩形端面。', SB_PROMPT)
    end

    def onMouseMove(_flags, x, y, view)
      picker = view.pick_helper
      picker.do_pick(x, y)
      # At the model level SketchUp often reports the enclosing Component as
      # `best_picked`. `leaf_at` is the actual geometric entity beneath it.
      @hover_face = picker.count > 0 ? picker.leaf_at(0) : nil
      @hover_path = picker.path_at(0) if picker.count > 0
      view.invalidate
    end

    def onLButtonDown(_flags, x, y, view)
      # Do not rely on the preceding mouse-move event: SketchUp can dispatch a
      # click before a fresh hover pick, especially immediately after a tool is
      # activated. Pick again at the click position.
      picker = view.pick_helper
      picker.do_pick(x, y)
      face = picker.count > 0 ? picker.leaf_at(0) : nil
      path = picker.count > 0 ? picker.path_at(0) : nil
      if @phase == :pin
        instance = picked_instance(face, path)
        if instance
          @controller.pin_board_clicked(instance)
          view.invalidate
          return
        end
      end
      unless face.is_a?(Sketchup::Face)
        UI.messagebox('請點選板材端頭的矩形「面」，不是邊線、控制點或空白處。')
        return
      end
      @controller.face_clicked(face, path, @phase)
      view.invalidate
    end

    def picked_instance(leaf, path)
      return leaf if leaf.is_a?(Sketchup::Group) || leaf.is_a?(Sketchup::ComponentInstance)
      items = path.respond_to?(:to_a) ? path.to_a : Array(path)
      items.reverse.find do |entity|
        entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
      end
    end

    def draw(view)
      face = @controller.current_board&.face || @hover_face
      if face.is_a?(Sketchup::Face)
        view.drawing_color = Sketchup::Color.new(64, 170, 255, 110)
        view.draw(GL_LINE_LOOP, face.outer_loop.vertices.map { |vertex| vertex.position.transform(@controller.current_board.instance.transformation) }) if @controller.current_board
      end
      board = @controller.current_board
      result = @controller.preview_result
      if @phase == :pin && board
        draw_pin_preview(view, @controller.pin_preview_polygons)
        return
      end
      return unless board && result && @phase == :tail

      view.line_width = 3
      view.drawing_color = Sketchup::Color.new(39, 204, 120)
      result.tails.each do |tail|
        points = tail[:polygon].map { |x, y| TailCutter.point(board, x, y, 0.0).transform(board.instance.transformation) }
        view.draw(GL_LINE_LOOP, points)
        center = Geom::Point3d.linear_combination(0.5, points[0], 0.5, points[2])
        view.draw_text(center, "T#{tail[:index]}")
      end
      draw_direction(view, board)
      view.line_width = 1
    end

    def draw_direction(view, board)
      start = TailCutter.point(board, 0.0, 0.0, 0.0).transform(board.instance.transformation)
      finish = TailCutter.point(board, [board.width * 0.2, 20.mm].max, 0.0, 0.0).transform(board.instance.transformation)
      view.drawing_color = Sketchup::Color.new(255, 190, 30)
      view.draw(GL_LINES, [start, finish])
      view.draw_text(finish, 'LEFT → RIGHT')
    end

    def draw_pin_preview(view, polygons)
      return unless polygons
      view.line_width = 3
      view.drawing_color = Sketchup::Color.new(255, 116, 92)
      polygons.each { |points| view.draw(GL_LINE_LOOP, points) }
      view.line_width = 1
    end
  end
end
