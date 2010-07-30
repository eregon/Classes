require_relative '../args'

class MinMax
  attr_reader :min, :max, :included
  def initialize(*args)
    case args
    when ARGS[Range]
      range = args[0]
      @min, @max = range.begin, range.end
      @included = !range.exclude_end?
      puts "wrong range" if @min >= @max
    when ARGS[[Numeric, Numeric], Boolean]
      @min, @max, @included = args.flatten
    when ARGS[Numeric, Numeric, Boolean]
      @min, @max, @included = args
    else
      raise ArgumentError
    end
  end

  def to_s
    if @included
      "[#{@min},#{@max}]"
    else
      "]#{@min},#{@max}["
    end
  end
  alias :inspect :to_s

  def map_with_other(o)
    [[@min, o.min], [@min, o.max],
    [@max, o.min], [@max, o.max]].map { |(a, b)|
      yield(a, b)
    }
  end

  def -@
    MinMax.new(-@max,-@min, @included)
  end

  def +(o)
    MinMax.new(@min+o.min, @max+o.max, @included & o.included)
  end
  def -(o)
    self + (-o)
  end
  def *(o)
    MinMax.new(
    map_with_other(o) { |a, b|
      a*b
    }.minmax,
    @included & o.included
    )
  end
  def /(o)
    MinMax.new(
    map_with_other(o) { |a, b|
      Rational(a,b)
    }.minmax,
    @included & o.included
    )
  end
end

if __FILE__ == $0
  a = MinMax.new 1..2
  b = MinMax.new 3...4
  p a+b
  p a-b
  p a*b
  p a/b
  p MinMax.new(0..0.48)-MinMax.new(0..12)+MinMax.new(0..0.0016)

  p ARGS[Array, Numeric] === [[],2]
  p ARGS[Numeric] === [2]
end