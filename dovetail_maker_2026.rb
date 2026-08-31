# frozen_string_literal: true

# Dovetail Maker 2026 extension loader. Install the enclosing RBZ from the
# SketchUp Extension Manager; SketchUp loads this small file at startup.
require 'sketchup.rb'
require 'extensions.rb'

module DovetailMaker2026
  EXTENSION_ID = 'com.dovetailmaker2026.v1'
  EXTENSION_NAME = 'Dovetail Maker 2026'
  EXTENSION_PATH = File.join(__dir__, 'DovetailMaker2026', 'main')

  unless file_loaded?(__FILE__)
    extension = SketchupExtension.new(EXTENSION_NAME, EXTENSION_PATH)
    extension.description = 'Creates through dovetails, tail first.'
    extension.version = '1.2.9'
    extension.creator = 'James Hook'
    extension.copyright = '2026'
    Sketchup.register_extension(extension, true)
    file_loaded(__FILE__)
  end
end
