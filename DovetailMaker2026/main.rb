# frozen_string_literal: true

require 'sketchup.rb'
require 'json'

module DovetailMaker2026
  require File.join(__dir__, 'settings')
  require File.join(__dir__, 'geometry_calculator')
  require File.join(__dir__, 'board_detector')
  require File.join(__dir__, 'tail_cutter')
  require File.join(__dir__, 'pin_cutter')
  require File.join(__dir__, 'dovetail_tool')
  require File.join(__dir__, 'dialog')

  class Controller
    attr_reader :current_board, :preview_result

    def initialize
      @model = Sketchup.active_model
      @settings = { thickness: Settings::DEFAULT_THICKNESS, tail_count: Settings::DEFAULT_TAIL_COUNT,
                    slope: Settings::DEFAULT_SLOPE, left_pin: Settings::DEFAULT_HALF_PIN,
                    right_pin: Settings::DEFAULT_HALF_PIN, flipped: false }
      @dialog = Dialog.new(self)
      @phase = :tail
      @tail_instance = nil
      @current_board = nil
      @preview_result = nil
      @other_tail_created = false
      @create_other_tail = false
    end

    def start
      @tail_instance = BoardDetector.validate_selection!(@model.selection)
      @phase = :tail
      @tail_layout = nil
      @other_tail_created = false
      @create_other_tail = false
      @current_board = BoardDetector.auto_detect(@tail_instance)
      @settings[:thickness] = @current_board.actual_thickness
      recalculate
      @model.select_tool(DovetailTool.new(self, :tail))
      @dialog.show
    rescue StandardError => e
      UI.messagebox(e.message.split('|', 2).last)
    end

    def dialog_ready
      send_state
    end

    def face_clicked(face, path, phase)
      instance = if phase == :tail
                   @tail_instance
                 else
                   instance_from_pick_path(path) || BoardDetector.validate_selection!(@model.selection)
                 end
      if phase == :pin && instance == @tail_instance
        raise ArgumentError, 'E104|請點選另一塊板材作為 Pin Board，不可再次選擇 Tail Board。'
      end
      ensure_face_belongs!(face, path, instance)
      @current_board = BoardDetector.detect(instance, face, @settings[:thickness], path)
      if phase == :tail
        recalculate
        @dialog.show
        send_state
      else
        @pin_board = @current_board
        @model.selection.clear
        @model.selection.add(@pin_board.instance)
        @tail_layout ||= PinCutter.read_tail_layout(@tail_instance)
        @dialog.show
        send_state
      end
    rescue ArgumentError => e
      UI.messagebox(e.message.split('|', 2).last)
    end

    def pin_board_clicked(instance)
      unless instance.is_a?(Sketchup::Group) || instance.is_a?(Sketchup::ComponentInstance)
        raise ArgumentError, 'E003|Pin Board 必須是 Group 或 Component。'
      end
      raise ArgumentError, 'E004|選取的 Pin Board 已鎖定。' if instance.locked?
      raise ArgumentError, 'E104|請點選另一塊板材作為 Pin Board。' if instance == @tail_instance

      @pin_board = BoardDetector.auto_detect_near(instance, @tail_joint_center, @settings[:thickness])
      validate_board_relationship!(@tail_board, @pin_board)
      @current_board = @pin_board
      @tail_layout ||= PinCutter.read_tail_layout(@tail_instance)
      @model.selection.clear
      @model.selection.add(instance)
      send_state
      @model.active_view.invalidate
    rescue StandardError => e
      UI.messagebox(e.message.split('|', 2).last)
    end

    def update_parameters(json)
      apply_parameters!(json)
      send_state
    rescue StandardError => e
      @preview_result = nil
      send_state(error: e.message.split('|', 2).last)
    ensure
      Sketchup.active_model.active_view.invalidate
    end

    def apply_parameters!(json)
      data = JSON.parse(json)
      # Parse into locals first. A temporarily empty/invalid field must not
      # corrupt the last valid settings while the user is still typing.
      # Board thickness is also an integer millimetre field, independent of
      # the model's current display units.
      thickness = Integer(data.fetch('thickness')).mm
      tail_count = Integer(data.fetch('tail_count'))
      slope = Integer(data.fetch('slope'))
      # Half Pin fields are integer millimetres, independent of model units.
      left_pin = Integer(data.fetch('left_pin')).mm
      right_pin = Integer(data.fetch('right_pin')).mm
      raise ArgumentError, 'E204|板厚或 Pin 尺寸格式無法辨識。' unless [thickness, left_pin, right_pin].all?

      candidate_board = BoardDetector.detect(@tail_instance, @current_board.face, thickness, @current_board.path)
      @settings.merge!(thickness: thickness, tail_count: tail_count, slope: slope,
                       left_pin: left_pin, right_pin: right_pin)
      @current_board = candidate_board
      recalculate
    end

    def flip(json = nil)
      apply_parameters!(json) if json
      @settings[:flipped] = !@settings[:flipped]
      recalculate
      send_state
      Sketchup.active_model.active_view.invalidate
    end

    def create_tail(json = nil)
      apply_parameters!(json) if json
      raise ArgumentError, '請先選取加工端面並輸入有效參數。' unless @current_board && @preview_result
      # Capture before make_unique/cutting, because those operations can replace
      # the definition and invalidate the originally detected Face reference.
      @tail_joint_center = @current_board.face.bounds.center.transform(@current_board.instance.transformation)
      opposite = BoardDetector.opposite_end(@tail_instance, @current_board.face, @settings[:thickness])
      @opposite_tail_center = opposite.face.bounds.center.transform(opposite.instance.transformation)
      @opposite_tail_width = opposite.width
      TailCutter.cut(@current_board, @preview_result)
      @tail_board = @current_board
      @tail_instance = @current_board.instance
      @tail_layout = PinCutter.read_tail_layout(@tail_instance)
      @phase = :pin
      @current_board = nil
      @preview_result = nil
      send_state(message: 'Tail 已建立。可勾選在完成時建立另一端的鏡像 Tail，或直接點選 Pin Board。')
      @model.select_tool(DovetailTool.new(self, :pin))
    rescue StandardError => e
      UI.messagebox(e.message.split('|', 2).last)
    end

    def set_create_other_tail(enabled)
      @create_other_tail = enabled == true || enabled.to_s == 'true'
      send_state
    end

    def create_pin
      raise ArgumentError, '請先選取 Pin Board 端面。' unless @pin_board && @tail_layout
      PinCutter.cut(@pin_board, @tail_layout)
      @phase = :complete
      send_state(message: 'Tail 與 Pin 已完成。按完成後可依勾選建立另一端的鏡像 Tail。')
      @model.select_tool(nil)
    rescue StandardError => e
      UI.messagebox(e.message.split('|', 2).last)
    end

    def pin_preview_polygons
      return nil unless @pin_board && @tail_layout
      PinCutter.preview_polygons(@pin_board, @tail_layout)
    rescue StandardError
      nil
    end

    def finish
      create_other_tail! if @create_other_tail && !@other_tail_created
      @model.select_tool(nil)
      @dialog.close
    rescue StandardError => e
      UI.messagebox(e.message.split('|', 2).last)
    end

    def dialog_closed
      @model.select_tool(nil)
    end

    def send_state(error: nil, message: nil)
      state = { phase: @phase.to_s, error: error, values: printable_values,
                create_other_tail: @create_other_tail, other_tail_created: @other_tail_created,
                about: { version: Settings::VERSION, release_date: Settings::RELEASE_DATE,
                         creator: Settings::CREATOR, email: Settings::EMAIL } }
      state[:message] = message if message
      if @preview_result
        state[:metrics] = { width: format_length(@preview_result.width), full_pin: format_length(@preview_result.full_pin),
                            tail_width: format_length(@preview_result.tail_width), narrow_width: format_length(@preview_result.narrow_width) }
      end
      @dialog.send_state(state)
    end

    private

    def create_other_tail!
      unless @tail_instance && @opposite_tail_center && @opposite_tail_width && @tail_layout
        raise ArgumentError, '請先建立第一端 Tail。'
      end

      first_layout = @tail_layout
      board = BoardDetector.auto_detect_near(@tail_instance, @opposite_tail_center, @settings[:thickness],
                                             expected_width: @opposite_tail_width)
      # The opposite end must be mirrored across the board width. Reversing the
      # layout also swaps the left/right half-pin treatment, producing a true
      # visual mirror rather than a second copy with the same handedness.
      result = GeometryCalculator.calculate(width: board.width, thickness: @settings[:thickness],
                                            tail_count: @settings[:tail_count], slope: @settings[:slope],
                                            left_pin: @settings[:left_pin], right_pin: @settings[:right_pin],
                                            flipped: !@settings[:flipped])
      TailCutter.cut(board, result)
      # The second cut writes its own layout attribute. Keep the first joint as
      # the authoritative Tail profile used for the already-created Pin Board.
      @tail_instance.set_attribute(Settings::DICTIONARY, 'tail_layout', JSON.generate(first_layout))
      @tail_layout = first_layout
      @other_tail_created = true
      @model.active_view.invalidate
    end

    def ensure_face_belongs!(face, path, instance)
      return if face.parent == BoardDetector.entities_for(instance)
      # A PickHelper path provides the selected group/component in ordinary
      # top-level and nested models. It avoids accepting an unrelated face.
      return if path && path.include?(instance)
      raise ArgumentError, 'E101|所選端面不屬於目前板件。'
    end

    def validate_board_relationship!(tail_board, pin_board)
      tail_inward = tail_board.inward_axis.transform(tail_board.instance.transformation).normalize
      tail_width = tail_board.x_axis.transform(tail_board.instance.transformation).normalize
      tail_thickness = tail_board.z_axis.transform(tail_board.instance.transformation).normalize
      pin_inward = pin_board.inward_axis.transform(pin_board.instance.transformation).normalize
      pin_width = pin_board.x_axis.transform(pin_board.instance.transformation).normalize
      correct_axes = tail_inward.dot(pin_inward).abs < 0.02 &&
                     tail_thickness.dot(pin_inward).abs > 0.98 &&
                     tail_width.dot(pin_width).abs > 0.98
      raise ArgumentError, 'E105|無法辨識正確的 Pin 端面；兩塊板須以 90° 完成位置擺放。' unless correct_axes
    end

    def instance_from_pick_path(path)
      return nil unless path
      items = path.respond_to?(:to_a) ? path.to_a : Array(path)
      items.reverse.find do |entity|
        entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
      end
    end

    def recalculate
      @preview_result = GeometryCalculator.calculate(width: @current_board.width, thickness: @settings[:thickness],
                                                     tail_count: @settings[:tail_count], slope: @settings[:slope],
                                                     left_pin: @settings[:left_pin], right_pin: @settings[:right_pin],
                                                     flipped: @settings[:flipped])
    end

    def printable_values
      { thickness: millimetres_integer(@settings[:thickness]), tail_count: @settings[:tail_count], slope: @settings[:slope],
        left_pin: millimetres_integer(@settings[:left_pin]), right_pin: millimetres_integer(@settings[:right_pin]),
        flipped: @settings[:flipped] }
    end

    def millimetres_integer(value)
      (value.to_f / 1.mm.to_f).round
    end

    def format_length(value)
      Sketchup.format_length(value)
    end
  end

  unless file_loaded?(__FILE__)
    UI.menu('Extensions').add_item('Dovetail Maker 2026') { Controller.new.start }
    toolbar = UI::Toolbar.new('Dovetail Maker 2026')
    command = UI::Command.new('Dovetail Maker 2026') { Controller.new.start }
    command.tooltip = 'Create through dovetails (Tail First)'
    command.small_icon = File.join(__dir__, 'ui', 'icons', 'dovetail-maker-24.png')
    command.large_icon = File.join(__dir__, 'ui', 'icons', 'dovetail-maker-32.png')
    toolbar.add_item(command)
    toolbar.restore
    file_loaded(__FILE__)
  end
end
