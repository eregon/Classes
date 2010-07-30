=begin
Class SVG
Scalable Vector Graphics
XML Image
Eregon - 2008

All angles are in degrees.
=end

require_relative 'xml'
require_relative '../math/point'

module XML
  class Node
    def href(str)
      str = (str.is_a? XML::Node) ? str['id'] : str.to_s
      str = str[1..-1] while str[0] == '#'
      set_attribute('xlink:href', "##{str}")
    end
    def transform(str)
      set_attribute('transform', str)
    end
  end
end

class SVG < XML::Document
=begin
String Name : filename
XML::Node 1 svg
Integer w, h : width, height
center
XML::Node 2 defs
=end
  attr_writer :name
  attr_reader :svg, :w, :h, :center, :defs

  #0<svg>
  def initialize(width, height, name = 'test.svg')
    super()
    @header = '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">'
    @svg = @root = XML::Node.new('svg')
    @precision = 3
    @w, @h = width, height
    @center = Point.new( (@w%2==0) ? @w/2 : (@w-1)/2, (@h%2==0) ? @h/2 : (@h-1)/2 )
    @name = name
    @svg.set_attributes([:width, width, :height, height, :version, '1.1',
    :xmlns, 'http://www.w3.org/2000/svg', :"xmlns:xlink", 'http://www.w3.org/1999/xlink'])
    @svg << XML::Node.new('title')
    @svg << @defs = XML::Node.new('defs')
    XML::Attributes.add_sort('default', ['id', 'xlink:href', 'class', '*', 'style'])
  end

  def SVG.draw(w, h, name = "test.svg", &block)
    svg = SVG.new(w, h)
    svg.instance_eval(&block)
    svg.save(name)
  end

  def save(name)
    name += '.svg' unless name[-4..-1] == '.svg'
    super(name)
  end

  #1<title>
  def title(str)
    @svg.get_children('title')[0].set_text(str)
  end

  #1<desc>
  def desc(description)
    @svg << XML::Node.new('desc').set_text(description)
  end

  #2<style>
  def style(css)
    @defs << XML::Node.new(:style, [:type, 'text/css']).set_CDATA("\n"+css+"\n")
  end

  #2<pattern>
  def pattern(id, x, y, width, height, patternUnits = 'userSpaceOnUse')
    @defs << XML::Node.new('pattern') * [:id, id, :x, x, :y, y, :width, width, :height, height, :patternUnits, patternUnits]
  end

  #2<marker>
  def marker(id, markerWidth, markerHeight, markerUnits = 'userSpaceOnUse', orient = 'auto', refX = 0, refY = 0)
    @defs << XML::Node.new('marker') * [:id, id, :markerWidth, markerWidth, :markerHeight, markerHeight, :markerUnits, markerUnits, :orient, orient, :refX, refX, :refY, refY]
  end

  #<image>
  def image(parent, href, x, y, width, height)
    XML::Node.new('image') * ['xlink:href', href, :x, x, :y, y, :width, "#{width}px", :height, "#{height}px"]
  end

  #<use>
  def use(path)
    path = (path.is_a? XML::Node) ? path['id'] : path.to_s
    XML::Node.new('use') * ['xlink:href', "##{path}"]
  end

  #<g>
  def g(style = '')
    XML::Node.new('g') * [:style, style]
  end

  #2<radialGradient>
  def radialGradient(id, r = 50, fx = 50, fy = 50, cx = 50, cy = 50)
    @defs << SVGGradient.new(:radial, id, r, fx, fy, cx, cy)
  end
  #2<linearGradient>
  def linearGradient(id, x1 = 0, y1 = 0, x2 = 100, y2 = 100)
    @defs << SVGGradient.new(:linear, id, x1, y1, x2, y2)
  end

  #<line>
  def line(p1, p2, style = '')
    XML::Node.new('line') * [:x1, p1.x, :y1, p1.y, :x2, p2.x, :y2, p2.y, :style, style]
  end
  #<polyline>
  def polyline(points, style = '')
    XML::Node.new('polyline')*[:points, points.join(' '), :style, style]
  end
  #<polygon>
  def polygon(points, style = '')
    XML::Node.new('polygon') * [:points, points.join(' '), :style, style]
  end
  #<rect>
  def rect(p1, p2, rx = '', ry = '', style = '')#left-top, right-bottom
    XML::Node.new('rect') * [:x, p1.x, :y, p1.y, :width, p2.x-p1.x, :height, p2.y-p1.y, :rx, rx, :ry, ry, :style, style]
  end
  #<ellipse>
  def ellipse(p, w, h, style = '')
    XML::Node.new('ellipse') * [:cx, p.x, :cy, p.y, :rx, w/2, :ry, h/2, :style, style]
  end
  #<circle>
  def circle(p, r, style = '')
    XML::Node.new('circle') * [:cx, p.x, :cy, p.y, :r, r, :style, style]
  end
  #<path>
  def path(d, style = '')
    XML::Node.new('path') * [:d, d, :style, style]
  end

  #<text>
  def text(str = '', p = nil, style = '')
    (p.nil?) ? XML::Node.new('text').set_text(str) * [:style, style] : XML::Node.new('text').set_text(str) * [:x, p.x, :y, p.y, :style, style]
  end
  #<tspan>
  def tspan(str, p, style = '')
    XML::Node.new('tspan').set_text(str) * [:x, p.x, :y, p.y, :style, style]
  end
  #<textPath>
  def textPath(path, str, style = '')
    path = (path.is_a? XML::Node) ? path['id'] : path.to_s
    XML::Node.new('text') << XML::Node.new('textPath').set_text(str) * ['xlink:href', '#'+path, :style, style]
  end
  #<tref>
  def tref(text)
    XML::Node.new('tref') * ['xlink:href', '#'+text['id']]
  end

  #<set>
  def set(attribute, attributeType, to, beg = '0s')
    XML::Node.new('set') * [:attributeName, attribute, :attributeType, attributeType, :to, to, :begin, beg]
  end
  #<animate>
  def animate(attribute, attributeType, from, to, beg, dur, fill = 'freeze')
    XML::Node.new('animate') * [:attributeName, attribute, :attributeType, attributeType, :from, from, :to, to, :begin, beg, :dur, dur, :fill, fill]
  end
  #<animateMotion>
  def animateMotion(path, beg, dur, fill = 'freeze')
    XML::Node.new('animateMotion') * [:begin, beg, :dur, dur, :path, path, :fill, fill]
  end
  #<mpath>
  def mpath(path)
    XML::Node.new('mpath') * ['xlink:href', '#'+path['id']]
  end
  #<animateColor>
  def animateColor(attribute, attributeType, from, to, beg, dur, fill = 'freeze')
    XML::Node.new('animateColor') * [:attributeName, attribute, :attributeType, attributeType, :from, from, :to, to, :begin, beg, :dur, dur, :fill, fill]
  end
  #<animateTransform>
  def animateTransform(type, from, to, beg, dur, fill = 'freeze')
    XML::Node.new('animateTransform') * [:attributeName, 'transform', :attributeType, 'XML', :type, type, :from, from, :to, to, :begin, beg, :dur, dur, :fill, fill]
  end

  #Special shapes
  def radius(p, length, number, angle, start_angle = 0, offset = 0, style = '')
    xml = []
    0.upto(number-1) { |r|
      xml << line(Point.new(p.x + offset*Math.cos((start_angle+angle*r)/180.0*Math::PI),
      p.y - offset*Math.sin((start_angle+angle*r)/180.0*Math::PI)),
      Point.new(p.x + (length+offset)*Math.cos((start_angle+angle*r)/180.0*Math::PI),
      p.y - (length+offset)*Math.sin((start_angle+angle*r)/180.0*Math::PI)), style)
    }
    xml
  end

  def arc(a, b, rx, ry, arc_flag = 0, sweep_flag = 0, style = '')
    XML::Node.new('path') * [:d, "M#{a} A#{rx},#{ry} 0 #{arc_flag},#{sweep_flag} #{b}", :style, style]
  end

  def relarc(a, b, rx, ry, arc_flag = 0, sweep_flag = 0, style = '')
    XML::Node.new('path') * [:d, "M#{a} a#{rx},#{ry} 0 #{arc_flag},#{sweep_flag} #{b}", :style, style]
  end

  def circle_arc(p, r, a_start, a_end, sweep_flag = true, style = '')
    arc_flag = 0
    s = Point.new(p.x+r*Math.cos(a_start/180.0*Math::PI), p.y-r*Math.sin(a_start/180.0*Math::PI))
    e = Point.new(p.x+r*Math.cos(a_end/180.0*Math::PI), p.y-r*Math.sin(a_end/180.0*Math::PI))
    sweep_flag = ((a_end-a_start)%360 > 180) ? 0 : 1 if(sweep_flag == true)
    arc(s, e, r, r, a_start, a_end, arc_flag, sweep_flag, style)
  end

  def text_aligned(center, str, font_size, style = '')
    cor = font_size/6
    text(str, center.add_y(font_size/2.8+cor), "text-anchor: middle; font-size: #{font_size}px;#{style}")
  end

  def rotated_text_aligned(center, str, font_size, angle = 0, text_look_up = false, style = '')
    angle += (angle == 180) ? -180 : 180 if(text_look_up && angle%360 > 90 && angle%360 < 270)
    cor = font_size/6
    text(str, center.add_y(font_size/2.8+cor), "text-anchor: middle font-size: #{font_size}px;#{style}") * [:transform, "rotate(#{-angle%360},#{center.add_y(cor)})"]
  end

  def eStar(center, n, r, style = '')
    #empty star, minimum 3 points
    #5:2*72, 6:2*60, 7:3*~51, 8:3*45, 9:4*40, 10:4*36
    step = (n-2+n%2)/2
    angle = 2*Math::PI/n
    offset = Math::PI/2 #top point
    points = []
    d = ''
    n.times { |p|
      points << Point.new(Math.cos(p*angle+offset)*r, -Math.sin(p*angle+offset)*r)
    }
    d = ''
    (n).times { |p|
      d += "M#{center+points[p]} L#{center+points[(p+step)%n]} "
    }
    path(d.rstrip, style)
  end

  def fStar(center, n, r_int, r_ext, style = '')
    #filled star, minimum 3 points
    angle = 2*Math::PI/n
    offset = Math::PI/2#top point
    points_ext, points_int = [], []
    for p in (0...n)
      points_ext << Point.new( Math.cos(p*angle+offset)*r_ext, -Math.sin(p*angle+offset)*r_ext )
      points_int << Point.new( Math.cos((p+0.5)*angle+offset)*r_int, -Math.sin((p+0.5)*angle+offset)*r_int )
    end
    d = "M#{center+points_ext[0]}"
    for i in (0...n-1)
      d += " L#{center+points_int[i]} L#{center+points_ext[i+1]}"
    end
    d += "L#{center+points_int[n-1]} z"
    path(d, style)
  end
end

#<path>
class SVGPath
  def initialize
    @arr = []
  end
  def add(str)
    @arr << str
    self
  end
  alias :<< :add

  def m(p)
    add "m#{p}"
  end
  def M(p)
    add "M#{p}"
  end

  def z
    add "z"
  end

  def l(*p) add "l#{p.join(' ')}"; end
  def L(*p) add "L#{p.join(' ')}"; end
  def h(x) add "h#{x}"; end
  def H(x) add "H#{x}"; end
  def v(y) add "v#{y}"; end
  def V(y) add "V#{y}"; end

  def q(c, e) add "q#{c} #{e}"; end
  def Q(c, e) add "Q#{c} #{e}"; end
  def t(p) add "t#{p}"; end

  def c(cb, ce, e)
    add "c#{cb} #{ce} #{e}"
  end
  def s(ce, e)
    add "s#{ce} #{e}"
  end

  def a(p, rotate, large_angle_flag, sweep_flag, e)
    add "a#{p} #{rotate} #{large_angle_flag},#{sweep_flag} #{e}"
  end
  def A(p, rotate, large_angle_flag, sweep_flag, e)
    add "A#{p} #{rotate} #{large_angle_flag},#{sweep_flag} #{e}"
  end

  def inspect
    @arr.join(' ')
  end
  alias :to_s :inspect
end

class SVGTime
  def initialize(arg)
    @v = case arg
    when Numeric
      arg
    when /^([0-9]+)s$/
      $1.to_i
    when /^([0-9]+)\\.([0-9]+)s$/
      $1.to_f
    end
  end

  def +(s)
    SVGTime.new(@v+s)
  end
  def -(s)
    SVGTime.new(@v-s)
  end

  def inspect
    "#{@v}s"
  end
  alias :to_s :inspect

  O = SVGTime.new('0s')
end

#2<radialGradient>, 2<linearGradient>, 3<stop>
class SVGGradient < XML::Node
  attr_reader :gradient, :stops

  def initialize(type, id, *args)
    case type.to_sym
    when :radial
      r = args[0] || 50
      fx = args[1] || 50; fy = args[2] || 50
      cx = args[3] || 50; cy = args[4] || 50
      super('radialGradient')
      self * [:id, id, :r, "#{r}%", :fx, "#{fx}%", :fy, "#{fy}%", :cx, "#{cx}%", :cy, "#{cy}%"]
    when :linear
      x1 = args[0] || 0; y1 = args[1] || 0
      x2 = args[2] || 100; y2 = args[3] || 100
      super('linearGradient')
      self * [:id, id, :x1, "#{x1}%", :y1, "#{y1}%", :x2, "#{x2}%", :y2, "#{y2}%"]
    else
      raise 'Unknown gradiant type'
    end
    @stops = []
  end

  def stop(offset, color, opacity = 1, style = '')
    @stops << XML::Node.new('stop') * [:offset, "#{offset}%", :style, "stop-color: #{color}; stop-opacity: #{opacity};#{style}"]
    self << @stops[-1]
    self
  end

  def from_to(from, to, op_from = 1, op_to = 1)
    stop(0, from, op_from)
    stop(100, to, op_to)
  end
end

if __FILE__ == $0
  p SVG.new(1,2)
end