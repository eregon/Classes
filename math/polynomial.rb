class Polynomial
  # [Numeric] coef : coefficients
  # Integer degree
  # String var
  attr_reader :coef
  attr_accessor :var

  def initialize(*args)
    args = [0] if args.empty?
    if block_given? && args.length == 1
      if args[0].to_i < 0
        @coef = args[0].to_i.abs.downto(0).map { |d| yield d }.reverse
      else
        @coef = Array.new(args[0].to_i+1) { |d| yield d }
      end
    else
      @coef = (args[0].is_a? Array) ? args[0] : args.reverse
    end
    @var = 'x'
  end

  def degree
    @coef.length-1
  end

  def simplify
    @coef.pop while @coef.last == 0
    @coef.map! { |c|
      if Rational === c and c.denominator == 1
        c.numerator
      elsif Float === c and c.to_i == c
        c.to_i
      else
        c
      end
    }
    @coef.empty? ? 0 : self
  end

  def ==(o)
    o.is_a?(Polynomial) && o.coef == @coef
  end

  def clone
    Polynomial.new(@coef)
  end
  alias :dup :clone

  def [](i)
    @coef[i]
  end
  def []=(i, v)
    @coef[i] = v
  end
  def each # each { |coef, degree| }
    if block_given?
      degree.downto(0) { |degree| yield(@coef[degree], degree) }
    else
      to_enum(:each)
    end
  end

  def inspect
    return '0' if @coef.all? { |c| c.zero? }
    @coef.reverse.each_with_index.inject("") { |s, (coef, i)|
      pow = @coef.length-1 - i
      if coef.zero?
        s
      else
        s <<
        (coef > 0 ? ' + ' : ' - ') << # sign
        (coef.abs == 1 && pow != 0 ? '' : coef.abs.to_s) << # coef
        (pow < 2 ? @var*pow : "#{@var}^#{pow}") # var
      end
    }.lstrip.sub(/^\+ /, '')
  end
  alias :to_s :inspect

  def +@
    self
  end
  def -@
    Polynomial.new(degree) { |d| -@coef[d] }
  end

  def +(o)
    case o
    when Polynomial
      min, max = [self, o].sort_by(&:degree)
      Polynomial.new(max.degree) { |d|
        (min[d] || 0) + max[d]
      }
    when Numeric
      Polynomial.new(@coef.dup.tap { |coef| coef[0] += o })
    end
  end
  def -(o)
    case o
    when Polynomial
      min, max = [self, o].sort_by(&:degree)
      Polynomial.new(max.degree) { |d|
        (min[d] || 0) - max[d]
      }
    when Numeric
      Polynomial.new(@coef.dup.tap { |coef| coef[0] -= o })
    end
  end
  def *(o)
    case o
    when Polynomial
      Polynomial.new(each.with_object( Array.new(degree+o.degree+1,0) ) { |(a, d), r|
        o.each { |b, e|
          r[d+e] += a*b
        }
      })
    when Numeric
      Polynomial.new(degree) { |d| @coef[d]*o }
    end
  end
  def /(o)
    case o
    when Numeric
      Polynomial.new(degree) { |d| @coef[d]/o.to_f }
    when Polynomial # Euclid division
      (degree-o.degree+1).times.inject([Polynomial.new, dup]) { |(quotient, rest),i|
        divide = Rational(rest[-1],o[-1]) * Polynomial.new(1,0)**(degree-o.degree-i)
        [quotient + divide, rest - divide * o].map(&:simplify)
      }
    end
  end
  # P(x) / (x-a)
  def horner(a, precision = 0)
    if (precision == 0 && run(a) != 0) || run(a).abs > 10**(-precision)
      raise 'P('+a.to_s+') != 0 (='+run(a).to_s+')'
    else
      Polynomial.new((degree-2).downto(0).inject([ @coef[-1] ]) { |coefs, d|
        coefs << @coef[d+1] + coefs[-1]*a
      }.reverse).simplify
    end
  end
  alias :% :horner
  def **(i)
    raise "i must be a positive Integer" unless Integer === i and i >= 0
    r = Polynomial.new(1)
    x = self.dup
    until i.zero?
      r *= x if i.odd?
      x *= x
      i /= 2
    end
    r
  end

  def old_power(power)
    power.to_i.times.inject(Polynomial.new(1)) { |r, i|
      r *= self
    }
  end

  def coerce(n)
    [Polynomial.new(n), self] if Numeric === n
  end

  def run(n)
    each.inject(0) { |r, (c, d)| r += c*n**d }
  end
  alias :& :run

  def derivative(n = 1)
    if n > 1
      n.times.inject(self, &:derivative)
    else
      return 0 if degree.zero?
      Polynomial.new(degree-1) { |d| @coef[d+1]*(d+1) }
    end
  end
  def integral(n = 1)
    if n > 1
      n.times.inject(self, &:integral)
    else
      Polynomial.new(degree+1) { |d| d.zero? ? 0 : Rational(@coef[d-1] , d) }.simplify
    end
  end
end

if __FILE__ == $0
  require 'minitest/autorun'
  class PolynomialTest < MiniTest::Unit::TestCase
    def setup
      @p1 = Polynomial.new(-3,-4,1,0,6)
      @p2 = Polynomial.new(1,0,2)
      @p3 = Polynomial.new(-1,-2,3,0)
      @p4 = Polynomial.new(0,0,0)
    end

    def test_unary_minus
      assert_equal Polynomial.new(3,4,-1,0,-6), -@p1
    end

    def test_add
      assert_equal Polynomial.new(-3,-4,1,0,8), @p1 + 2
      assert_equal Polynomial.new(-3,-5,-1,3,6), @p1+@p3
    end

    def test_sub
      assert_equal Polynomial.new(1,3,-3,2), @p2-@p3
    end

    def test_mul
      assert_equal Polynomial.new(3, 10, -2, -14, -3, -12, 18, 0), @p1*@p3
    end

    def test_horner
      assert_equal Polynomial.new(-3, -7, -6, -6), @p1.horner(1)
      assert_equal [Polynomial.new(-3, -7, -6, -6), 0], @p1/Polynomial.new(1, -1)
    end

    def test_division
      p = Polynomial.new(1,-2,1,0,2)
      q = Polynomial.new(1,-1,1,-1)
      assert_equal [Polynomial.new(1,-1),Polynomial.new(-1,2,1)], p/q
    end

    def test_derivative
      assert_equal 0, Polynomial.new(2).derivative
      assert_equal Polynomial.new(-12,-12,2,0), @p1.derivative
      assert_equal Polynomial.new(-36,-24,2), @p1.derivative(2)
    end

    def test_integral
      assert_equal Polynomial.new(-3,-4,1,0,0), Polynomial.new(-12,-12,2,0).integral
      assert_equal Polynomial.new(Rational(1,12),0,1,0,0), @p2.integral(2)
    end

    # tests of #to_s
    def test_to_s
      assert_equal "- 3x^4 - 4x^3 + x^2 + 6", @p1.to_s
      assert_equal "x^2 + 2", @p2.to_s
      assert_equal "- x^3 - 2x^2 + 3x", @p3.to_s
      assert_equal "0", @p4.to_s
      assert_equal "3x^2 - 2x + 1", Polynomial.new(3,-2,+1).to_s
      assert_equal "- 43x^4 + 5x^2 - 1", Polynomial.new(-43,0,5,0,-1).to_s
      assert_equal "2x + 11", Polynomial.new(2,11).to_s
      assert_equal "- x^8 + 12x^6 - 2x^4 + x - 9", Polynomial.new(-1,0,12,0,-2,0,0,1,-9).to_s
      assert_equal "x^2 + 5x + 6", Polynomial.new(0,0,1,5,6).to_s
      assert_equal "- 4.1x^2 - 5.45", Polynomial.new(-4.1,0,-5.45).to_s
      assert_equal "x^15 + x", Polynomial.new(1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0).to_s
      assert_equal "100", Polynomial.new(0, 0, 0, 0, 100).to_s
      assert_equal "x^8 + 2x^6 + 3x^3", Polynomial.new(0,0, 1,0,2, 0,0,3, 0,0,0).to_s
      assert_equal "0", Polynomial.new.to_s
    end
  end
end