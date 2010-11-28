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

  { :+ => '++', :- => '--', :>> => '+-', :<< => '-+' }.each_pair do |op, expr|
    class_eval "def #{op}(o)
      case o
      when Point
        self.class.new(@x #{expr[0]} o.x, @y #{expr[1]} o.y)
      when Numeric
        self.class.new(@x #{expr[0]} o, @y #{expr[1]} o)
      end
    end"
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
    @x, @y = [@x, @y].map { |v| !(Integer === v) && v == v.to_i ? v.to_i : v }
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

require 'rspec'
describe Point do
  it '+' do
    (Point.new(2,3) + Point.new(3,4)).should == Point.new(5,7)
    (Point.new(2,3) + 4).should == Point.new(6,7)
  end
  it '>>' do
    (Point.new(2,3) >> Point.new(1,1)).should == Point.new(3,2)
    (Point.new(2,3) >> 1).should == Point.new(3,2)
  end
end
