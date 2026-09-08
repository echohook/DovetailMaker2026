# frozen_string_literal: true

module DovetailMaker2026
  # Reconstruct joints from model faces/edges, including the opposite end made
  # by <= 1.2.10 (which only persisted the first end's coordinate system).
  module TailJoints
    def self.available?(instance)
      !!instance.get_attribute(Settings::DICTIONARY, 'tail_layout')
    end

    def self.read(instance)
      seed = PinCutter.read_tail_layout(instance)
      saved = instance.get_attribute(Settings::DICTIONARY, 'tail_layouts')
      saved = saved ? JSON.parse(saved) : [seed]
      candidates = saved + [seed]
      origin = Geom::Point3d.new(seed.fetch('origin'))
      inward = Geom::Vector3d.new(seed.fetch('inward_axis'))
      vertices = BoardDetector.entities_for(instance).grep(Sketchup::Edge).flat_map(&:vertices)
      length = vertices.map { |v| (v.position - origin).dot(inward) }.max
      if length && length > 2 * seed.fetch('thickness').to_f
        candidates << seed.merge('origin' => origin.offset(inward, length).to_a.map(&:to_f),
                                 'inward_axis' => inward.reverse.to_a.map(&:to_f))
      end
      joints = candidates.filter_map { |layout| extract(instance, layout) }
      joints = joints.uniq { |layout| center(layout).to_a.map { |n| (n / tolerance).round } }
      raise ArgumentError, 'E405|找不到完整的既有 Tail 輪廓；請確認板材的榫頭未被修改或復原。' if joints.empty?
      joints
    end

    def self.extract(instance, frame)
      thickness = frame.fetch('thickness').to_f
      origin = Geom::Point3d.new(frame.fetch('origin'))
      axes = %w[x_axis inward_axis z_axis].map { |key| Geom::Vector3d.new(frame.fetch(key)) }
      coordinates = lambda do |point|
        delta = point - origin
        axes.map { |axis| delta.dot(axis) }
      end
      entities = BoardDetector.entities_for(instance)
      # Sloped broad-face boundary edges connect the end to the baseline.
      slopes = entities.grep(Sketchup::Edge).filter_map do |edge|
        points = edge.vertices.map { |v| coordinates.call(v.position) }.sort_by { |p| p[1] }
        a, b = points
        next unless a[1].abs <= tolerance && (b[1] - thickness).abs <= tolerance
        next unless (a[2] - b[2]).abs <= tolerance
        next unless a[2].abs <= tolerance || (a[2] - thickness).abs <= tolerance
        [a[0], b[0], a[2]]
      end
      ends = entities.grep(Sketchup::Face).filter_map do |face|
        points = face.outer_loop.vertices.map { |v| coordinates.call(v.position) }
        next unless face.loops.length == 1 && points.length == 4 && points.all? { |p| p[1].abs <= tolerance }
        zs = points.map(&:last)
        next unless zs.min.abs <= tolerance && (zs.max - thickness).abs <= tolerance
        xs = points.map(&:first)
        [xs.min, xs.max]
      end
      tails = ends.filter_map do |left, right|
        # Both broad sides must describe the same actual trapezoid.
        inner = [0.0, thickness].map do |z|
          a = slopes.find { |x, _y, side| (x - left).abs <= tolerance && (side - z).abs <= tolerance }
          b = slopes.find { |x, _y, side| (x - right).abs <= tolerance && (side - z).abs <= tolerance }
          a && b ? [a[1], b[1]] : nil
        end
        next if inner.any?(&:nil?)
        next unless inner[0].zip(inner[1]).all? { |a, b| (a - b).abs <= tolerance }
        il, ir = inner.first
        next unless il > left + tolerance && ir < right - tolerance && ir > il + tolerance
        [[left, 0.0], [right, 0.0], [ir, thickness], [il, thickness]]
      end.sort_by { |tail| tail.first.first }
      return nil if tails.empty? || tails.length != ends.length
      frame.merge('tails' => tails, 'transformation' => instance.transformation.to_a.map(&:to_f))
    end

    def self.center(layout)
      PinCutter.tail_point(layout, layout.fetch('width').to_f / 2, 0, layout.fetch('thickness').to_f / 2)
    end

    def self.tolerance
      Settings::GEOMETRY_TOLERANCE * 10
    end
  end
end
