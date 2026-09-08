# frozen_string_literal: true
# Geometry/API doubles: exercise production detection and controller paths.
# Run with Ruby 3.2: ruby test/regression.rb (no SketchUp installation required).
require 'json'
class Numeric
  def mm = to_f / 25.4
end
module Geom
  class Vector3d
    attr_reader :x, :y, :z
    def initialize(*args) = (@x, @y, @z = args.flatten.map(&:to_f))
    def to_a = [x, y, z]
    def dot(v) = x * v.x + y * v.y + z * v.z
    def cross(v) = Vector3d.new(y*v.z-z*v.y, z*v.x-x*v.z, x*v.y-y*v.x)
    def length = Math.sqrt(dot(self))
    def normalize = Vector3d.new(to_a.map { |n| n / length })
    def reverse = Vector3d.new(-x, -y, -z)
    def transform(t) = t.vector(self)
  end
  class Point3d < Vector3d
    def -(p) = Vector3d.new(x-p.x, y-p.y, z-p.z)
    def distance(p) = (self-p).length
    def offset(v, d) = Point3d.new(x+v.x*d, y+v.y*d, z+v.z*d)
    def transform(t) = t.point(self)
    def project_to_plane(plane)
      origin, normal = plane
      offset(normal, -((self-origin).dot(normal)) / normal.dot(normal))
    end
  end
  class Transformation
    def initialize(a = nil)
      @a = a || [1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]
    end
    def to_a = @a
    def vector(v)
      Vector3d.new(3.times.map { |i| @a[i]*v.x+@a[i+4]*v.y+@a[i+8]*v.z })
    end
    def point(p)
      v = vector(p)
      Point3d.new(v.x+@a[12], v.y+@a[13], v.z+@a[14])
    end
    def inverse
      a = [@a[0],@a[4],@a[8],0, @a[1],@a[5],@a[9],0, @a[2],@a[6],@a[10],0, 0,0,0,1]
      v = Transformation.new(a).vector(Vector3d.new(@a[12],@a[13],@a[14]))
      a[12,3] = v.reverse.to_a
      Transformation.new(a)
    end
  end
end
module Sketchup
  Vertex = Struct.new(:position)
  Loop = Struct.new(:vertices)
  class Bounds
    def initialize(points) = (@points = points)
    def center = Geom::Point3d.new(3.times.map { |i| v=@points.map { |p| p.to_a[i] }; (v.min+v.max)/2 })
  end
  class Face
    attr_reader :outer_loop, :normal, :parent
    def initialize(points, parent)
      @parent = parent
      @outer_loop = Loop.new(points.map { |p| Vertex.new(p) })
      @normal = (points[1]-points[0]).cross(points[2]-points[0]).normalize
    end
    def loops = [outer_loop]
    def bounds = Bounds.new(outer_loop.vertices.map(&:position))
    def area
      pts = outer_loop.vertices.map(&:position)
      (pts[1]-pts[0]).cross(pts[-1]-pts[0]).length
    end
  end
  class Edge
    attr_reader :vertices
    def initialize(a,b) = (@vertices = [Vertex.new(a),Vertex.new(b)])
  end
  class Entities < Array
    def face(points)
      f = Face.new(points.map { |p| Geom::Point3d.new(p) }, self)
      self << f
      pts = f.outer_loop.vertices.map(&:position)
      pts.each_with_index { |p,i| self << Edge.new(p,pts[(i+1)%pts.size]) }
      f
    end
  end
  class Group
    attr_accessor :transformation
    attr_reader :entities
    def initialize
      @entities = Entities.new
      @attributes = {}
      @transformation = Geom::Transformation.new
    end
    def locked? = false
    def get_attribute(dict,key) = @attributes[[dict,key]]
    def set_attribute(dict,key,value) = (@attributes[[dict,key]] = value)
  end
  class ComponentInstance < Group
    def definition = self
  end
  class Selection < Array
    def add(x) = (self << x)
  end
  class View
    def invalidate; end
  end
  class Model
    attr_reader :selection, :active_view
    def initialize
      @selection = Selection.new
      @active_view = View.new
    end
    def select_tool(tool) = (@tool = tool)
  end
  def self.active_model = (@model ||= Model.new)
  def self.format_length(n) = n.to_s
end
module UI
  def self.messagebox(message) = raise(message)
end
def file_loaded?(_file) = true
$LOADED_FEATURES << 'sketchup.rb'
require_relative '../DovetailMaker2026/main'
module DovetailMaker2026
  class Dialog
    attr_reader :state
    def show; end
    def send_state(state) = (@state = state)
  end
end
include DovetailMaker2026
def assert(condition, message)
  raise message unless condition
end
def rejects(message)
  begin
    yield
  rescue ArgumentError
    return
  end
  raise message
end

W = 517.6.mm
T = 18.mm
L = 600.mm
FRAME = {'origin'=>[0,0,0], 'x_axis'=>[1,0,0], 'inward_axis'=>[0,1,0], 'z_axis'=>[0,0,1],
         'width'=>W, 'thickness'=>T, 'transformation'=>Geom::Transformation.new.to_a}

def profile(left, right, count = 4)
  GeometryCalculator.calculate(width: W, thickness: T, tail_count: count, slope: 6,
                               left_pin: left.mm, right_pin: right.mm).tails.map { |t| t[:polygon] }
end
def teeth(tails)
  [[0,T]] + tails.flat_map { |t| [t[3],t[0],t[1],t[2]] } + [[W,T]]
end
def tail_board(front, back = nil, type = Sketchup::Group)
  board = type.new
  polygon = teeth(front)
  polygon += back ? teeth(back).reverse.map { |x,y| [x,L-y] } : [[W,L],[0,L]]
  board.entities.face(polygon.map { |x,y| [x,y,0] })
  board.entities.face(polygon.reverse.map { |x,y| [x,y,T] })
  polygon.each_with_index do |a,i|
    b = polygon[(i+1)%polygon.size]
    board.entities.face([[a[0],a[1],0],[b[0],b[1],0],[b[0],b[1],T],[a[0],a[1],T]])
  end
  # Exactly the legacy format: only first-end metadata, no second layout.
  board.set_attribute(Settings::DICTIONARY,'tail_layout',JSON.generate(FRAME.merge('tails'=>front)))
  board
end
def pin_board(y)
  board = Sketchup::Group.new
  x0,x1 = 0,W
  y0,y1 = y,y+T
  z0,z1 = -300.mm,T
  board.entities.face([[x0,y0,z1],[x1,y0,z1],[x1,y1,z1],[x0,y1,z1]])
  board.entities.face([[x0,y1,z0],[x1,y1,z0],[x1,y0,z0],[x0,y0,z0]])
  board.entities.face([[x0,y0,z0],[x1,y0,z0],[x1,y0,z1],[x0,y0,z1]])
  board.entities.face([[x1,y1,z0],[x0,y1,z0],[x0,y1,z1],[x1,y1,z1]])
  board.entities.face([[x0,y1,z0],[x0,y0,z0],[x0,y0,z1],[x0,y1,z1]])
  board.entities.face([[x1,y0,z0],[x1,y1,z0],[x1,y1,z1],[x1,y0,z1]])
  board
end
front = profile(4,7)
back = profile(7,4)
source = tail_board(front,back)
joints = TailJoints.read(source)
assert(joints.size == 2, 'legacy second end missing')
assert(joints[1]['tails'].first.first.first == back.first.first.first, 'asymmetric opposite outline changed')
assert(TailJoints.read(tail_board(front)).size == 1, 'uncut opposite end treated as Tail')
assert(TailJoints.read(tail_board(front,back,Sketchup::ComponentInstance)).size == 2, 'component recovery')
first_pin = pin_board(0)
last_pin = pin_board(L-T)
board,layout = PinCutter.match_joint(last_pin,joints)
assert((TailJoints.center(layout).y-L).abs < 1e-8, 'second Pin used first Tail')
assert(board.inward_axis.z < -0.99, 'wrong Pin side face selected')
assert(PinCutter.preview_polygons(board,layout).size == 4, 'missing Pin preview')
assert(TailJoints.center(PinCutter.match_joint(first_pin,joints).last).y.abs < 1e-8, 'first Pin used second Tail')
rejects('far-away Pin was accepted') { PinCutter.match_joint(pin_board(200.mm),joints) }
rejects('legacy shoulders used as new blank width') { BoardDetector.auto_detect(source) }

# Data survives save/reload; geometry modified after saving is read afresh.
source.set_attribute(Settings::DICTIONARY,'tail_layouts',JSON.generate(joints))
assert(TailJoints.read(source).size == 2, 'saved joints reload')
changed = tail_board(profile(5,8),back)
changed.set_attribute(Settings::DICTIONARY,'tail_layout',source.get_attribute(Settings::DICTIONARY,'tail_layout'))
assert((TailJoints.read(changed).first['tails'].first.first.first-5.mm).abs < 1e-8, 'cached values override geometry')

# Moved/rotated instances must use their current transform, including legacy.
rotation = Geom::Transformation.new([0,1,0,0, -1,0,0,0, 0,0,1,0, 10,20,30,1])
source.transformation = rotation
last_pin.transformation = rotation
assert(PinCutter.match_joint(last_pin,TailJoints.read(source)).last['transformation'] == rotation.to_a, 'stale transform')

# Reopening an existing Tail must never enter layout calculations (E205).
module NoRecalculation
  def calculate(**args)
    raise 'Existing Tail triggered width recalculation' if $forbid_calculate
    super
  end
end
GeometryCalculator.singleton_class.prepend(NoRecalculation)
$forbid_calculate = true
Sketchup.active_model.selection.add(source)
controller = Controller.new
controller.start
controller.dialog_ready
dialog = controller.instance_variable_get(:@dialog)
assert(dialog.state[:phase] == 'select_pin', 'resume phase')
assert(dialog.state[:can_create_other_tail] == false, 'resume offered duplicate Tail')
controller.update_parameters('{}') # queued old HTML update must be ignored
controller.pin_board_clicked(last_pin)
assert(dialog.state[:phase] == 'pin', 'Pin not ready after resume')
begin
  controller.pin_board_clicked(source)
rescue RuntimeError
end
assert(controller.current_board.nil?, 'invalid selection kept a stale valid Pin')
assert(dialog.state[:phase] == 'select_pin' && dialog.state[:error], 'invalid selection did not disable Create')
puts 'PASS: legacy/reloaded two-end joints, actual outlines, asymmetric halves, groups/components, rotated/moved boards, Pin end matching, invalid placements, resume without recalculation, stale callbacks and selection clearing.'
