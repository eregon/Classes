require_relative 'rational'

class EVector
  class Scalar # Numeric <op> EVector
    def initialize(n)
      @n = n
    end

    def * v # Numeric * EVector
      v * @n
    end
  end

  attr_reader :elements
  def initialize(*elements)
    if elements.size == 1 and Array == elements[0].class
      @elements = elements[0]
    else
      @elements = elements
    end
  end
  def self.[](*args)
    self.new(*args)
  end
  def new(*args)
    EVector.new(*args)
  end

  def == o
    EVector === o and @elements == o.elements
  end
  def eql? o
    EVector === o and @elements.eql? o.elements
  end

  [:+, :-].each { |meth|
    define_method(meth) do |v|
      raise ArgumentError, "Cannot add #{v} to #{self}" unless EVector === v
      raise ArgumentError, "Dimensions miss match" unless size == v.size
      new(Array.new(size) { |i| self[i].send meth, v[i] })
    end
  }

  def * o
    case o
    when Numeric
      new @elements.map { |e|
        e * o
      }
    when EVector # inner product
      (0...size).inject(0) { |ip, i| ip + self[i] * o[i] }
    end
  end

  def / o
    raise "#{self.class} can only be divided by a numeric value" unless o.is_a? Numeric
    new(@elements.map { |e| Rational(e,o).simplify })
  end

  def distance
    Math.sqrt( @elements.inject(0) {|v, e| v + e*e} )
  end

  def method_missing(meth, *args, &block)
    if [:size, :[], :hash, :to_a, :each, :each_with_index, :map].include? meth
      @elements.send(meth, *args, &block)
    else
      super
    end
  end

  def coerce(other)
    if Numeric === other
      [EVector::Scalar.new(other), self]
    else
      raise TypeError, ": #{self.class} can't be coerced into #{other.class}"
    end
  end

  def to_a
    @elements
  end
  def to_s
    "(#{elements.join(', ')})"
  end
  def inspect
    "EVector#{elements.inspect}"
  end
end

if __FILE__ == $0
  v = EVector[1,2,3]
  w = EVector[2,3,4]
  p v+w
  p w-v

  p v*w
  p v
  puts v

  require "minitest/autorun"
  class TestEVector < MiniTest::Unit::TestCase
    def setup
      @v = EVector[-1,2,3]
      @w = EVector[2,3,4]
    end

    def test_add
      assert_equal EVector[2,4,7], @v+EVector[3,2,4]
    end

    def test_mul
      assert_equal EVector[4,6,8], @w*2
    end

    def test_div
      assert_equal @w, @w*2/2
    end

    def test_coerce
      r = rand(5)-2
      assert_equal @v*r, r*@v
      assert_raises(NoMethodError) { 7+@v }
      assert_raises(NoMethodError) { 7-@v }
      assert_raises(NoMethodError) { 7/@v }
    end
  end
end