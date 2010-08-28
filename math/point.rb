#
# Class self.class
# point : (x,y)
# Eregon - 2008

class Point
  class Scalar # Numeric <op> Point
    def initialize(n)
      @n = n
    end

    def * p # Numeric * Point
      p * @n
    end
  end

  attr_accessor :x, :y
  def initialize(x, y)
    @x, @y = x, y
  end

  def == o
    self.class === o and @x == o.x and @y == o.y
  end

  # Hash stuff
  alias :eql? :==
  def hash
    @x ^ @y
  end

  def -@
    self.class.new(-@x, -@y)
  end
  def +(o)
    case o
    when Point
      self.class.new(@x+o.x, @y+o.y)
    when Numeric
      self.class.new(@x+o, @y+o)
    end
  end
  def -(o)
    case o
    when Point
      self.class.new(@x-o.x, @y-o.y)
    when Numeric
      self.class.new(@x-o, @y-o)
    end
  end
  def *(n)
    self.class.new(@x*n, @y*n)
  end
  def /(n)
    self.class.new(Rational(@x, n), Rational(@y, n))
  end

  def coerce(other)
    [Scalar.new(other), self]
  end

  def >>(o) # + -
    case o
    when Point
      self.class.new(@x+o.x, @y-o.y)
    when Numeric
      self.class.new(@x+o, @y-o)
    end
  end
  def <<(o) # - +
    case o
    when Point
      self.class.new(@x-o.x, @y+o.y)
    when Numeric
      self.class.new(@x-o, @y+o)
    end
  end

  def add_x(v)
    self.class.new(@x+v, @y)
  end
  def sub_x(v)
    self.class.new(@x-v, @y)
  end
  def add_y(v)
    self.class.new(@x, @y+v)
  end
  def sub_y(v)
    self.class.new(@x, @y-v)
  end

  def med(p)
    (self+p)/2.0
  end

  def distance(p)
    Math.hypot(p.x - self.x, p.y - self.y)
  end
  alias :length :distance

  def to_s
    @x = @x.to_i if !(Integer === @x) and @x == @x.to_i
    @y = @y.to_i if !(Integer === @y) and @y == @y.to_i
    "#{@x},#{@y}"
  end
  def inspect
    "(#{self})"
  end

  O = Point.new( 0, 0)#.freeze
  N = Point.new( 0,-1)#.freeze
  E = Point.new( 1, 0)#.freeze
  S = Point.new( 0, 1)#.freeze
  W = Point.new(-1, 0)#.freeze
  DIRECTIONS = [N, E, S, W]#.freeze
end