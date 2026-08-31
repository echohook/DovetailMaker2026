# frozen_string_literal: true

module DovetailMaker2026
  class Dialog
    def initialize(controller)
      @controller = controller
      @dialog = nil
    end

    def show
      return @dialog.bring_to_front if @dialog && @dialog.visible?
      @dialog = UI::HtmlDialog.new(dialog_options)
      @dialog.set_file(File.join(__dir__, 'ui', 'dialog.html'))
      @dialog.add_action_callback('ready') { |_ctx| @controller.dialog_ready }
      @dialog.add_action_callback('update') { |_ctx, data| @controller.update_parameters(data) }
      @dialog.add_action_callback('flip') { |_ctx, data| @controller.flip(data) }
      @dialog.add_action_callback('set_create_other_tail') { |_ctx, enabled| @controller.set_create_other_tail(enabled) }
      @dialog.add_action_callback('create_tail') { |_ctx, data| @controller.create_tail(data) }
      @dialog.add_action_callback('create_pin') { |_ctx| @controller.create_pin }
      @dialog.add_action_callback('finish') { |_ctx| @controller.finish }
      @dialog.set_on_closed { @controller.dialog_closed }
      @dialog.show
    end

    def send_state(state)
      return unless @dialog && @dialog.visible?
      @dialog.execute_script("window.DovetailMaker.receive(#{JSON.generate(state)});")
    end

    def close
      @dialog.close if @dialog
    end

    private

    def dialog_options
      { dialog_title: 'Dovetail Maker 2026', preferences_key: 'DovetailMaker2026',
        scrollable: true, resizable: false, width: 380, height: 545,
        style: UI::HtmlDialog::STYLE_DIALOG }
    end
  end
end
