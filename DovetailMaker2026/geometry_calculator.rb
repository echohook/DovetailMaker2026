# frozen_string_literal: true

module DovetailMaker2026
  # Pure local-coordinate math. x runs across the selected end face; y runs
  # from its outside edge into the board. No SketchUp entities are changed here.
  class GeometryCalculator
    Result = Struct.new(:width, :thickness, :tail_count, :slope, :left_pin,
                        :right_pin, :full_pin, :tail_width, :narrow_width,
                        :offset, :tails, :wastes, keyword_init: true)

    def self.calculate(width:, thickness:, tail_count:, slope:, left_pin:, right_pin:, flipped: false)
      validate!(width, thickness, tail_count, slope, left_pin, right_pin)
      full_pin = left_pin + right_pin
      tail_width = (width - left_pin - right_pin - (tail_count - 1) * full_pin) / tail_count.to_f
      raise ArgumentError, 'E205|目前 Tail 數量與 Pin 寬度超出板材可用寬度。' unless tail_width > Settings::GEOMETRY_TOLERANCE

      offset = thickness / slope.to_f
      narrow_width = tail_width - 2.0 * offset
      raise ArgumentError, 'E206|目前板厚、斜率與 Tail 配置會造成 Tail 窄端無法成立。' unless narrow_width > Settings::GEOMETRY_TOLERANCE

      tails = []
      cursor = left_pin
      tail_count.times do |index|
        outer_left = cursor
        outer_right = outer_left + tail_width
        tails << {
          index: index + 1,
          outer_left: outer_left, outer_right: outer_right,
          inner_left: outer_left + offset, inner_right: outer_right - offset,
          polygon: [[outer_left, 0.0], [outer_right, 0.0], [outer_right - offset, thickness], [outer_left + offset, thickness]]
        }
        cursor = outer_right + full_pin
      end

      if flipped
        tails = tails.map do |tail|
          outer_left = width - tail[:outer_right]
          outer_right = width - tail[:outer_left]
          inner_left = width - tail[:inner_right]
          inner_right = width - tail[:inner_left]
          tail.merge(outer_left: outer_left, outer_right: outer_right,
                     inner_left: inner_left, inner_right: inner_right,
                     polygon: [[outer_left, 0.0], [outer_right, 0.0], [inner_right, thickness], [inner_left, thickness]])
        end.reverse
      end
      # Waste polygons are the complementary regions, measured from the same
      # x=0 reference. These are what TailCutter removes.
      ordered = tails.sort_by { |tail| tail[:outer_left] }
      breaks = [0.0] + ordered.flat_map { |tail| [tail[:outer_left], tail[:outer_right]] } + [width]
      wastes = []
      current_left = 0.0
      ordered.each_with_index do |tail, i|
        inner_left = i.zero? ? 0.0 : ordered[i - 1][:inner_right]
        wastes << [[current_left, 0.0], [tail[:outer_left], 0.0], [tail[:inner_left], thickness], [inner_left, thickness]]
        current_left = tail[:outer_right]
      end
      last_inner = ordered.empty? ? width : ordered.last[:inner_right]
      wastes << [[current_left, 0.0], [width, 0.0], [width, thickness], [last_inner, thickness]]
      wastes.reject! { |polygon| polygon_area(polygon) <= Settings::MIN_FACE_AREA }

      Result.new(width: width, thickness: thickness, tail_count: tail_count, slope: slope,
                 left_pin: left_pin, right_pin: right_pin, full_pin: full_pin,
                 tail_width: tail_width, narrow_width: narrow_width, offset: offset,
                 tails: tails, wastes: wastes)
    end

    def self.validate!(width, thickness, count, slope, left, right)
      raise ArgumentError, 'E204|板厚必須大於 0。' unless thickness > Settings::GEOMETRY_TOLERANCE
      raise ArgumentError, 'E201|Tail 數量至少必須為 1。' unless count.is_a?(Integer) && count >= 1
      raise ArgumentError, 'E202|左半 Pin 寬度必須大於 0。' unless left > Settings::GEOMETRY_TOLERANCE
      raise ArgumentError, 'E203|右半 Pin 寬度必須大於 0。' unless right > Settings::GEOMETRY_TOLERANCE
      raise ArgumentError, 'E207|Tail 斜率必須是 1:4 至 1:8。' unless Settings::SLOPES.include?(slope)
      raise ArgumentError, 'E205|所選端面沒有可用板寬。' unless width > Settings::GEOMETRY_TOLERANCE
    end

    def self.polygon_area(points)
      points.each_with_index.sum { |point, index| point[0] * points[(index + 1) % points.length][1] - points[(index + 1) % points.length][0] * point[1] }.abs / 2.0
    end
  end
end
