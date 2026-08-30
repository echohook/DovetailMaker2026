# frozen_string_literal: true

module DovetailMaker2026
  module Settings
    VERSION = '1.2.6'
    RELEASE_DATE = '2026-08-31'
    CREATOR = 'James Hook'
    EMAIL = 'dark.hook@gmail.com'
    SLOPES = [4, 5, 6, 7, 8].freeze
    DEFAULT_THICKNESS = 18.mm
    DEFAULT_TAIL_COUNT = 4
    DEFAULT_SLOPE = 6
    DEFAULT_HALF_PIN = 4.mm
    CLEARANCE = 0.0
    GEOMETRY_TOLERANCE = 0.001.mm
    MIN_FACE_AREA = 0.01.mm * 0.01.mm
    DICTIONARY = 'DovetailMaker2026'
  end
end
