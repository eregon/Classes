# encoding: utf-8
require_relative '../core/kernel'
require_relative 'numeric'
require_relative 'rational'
require_relative 'vector'

class EMatrix
  class Scalar # Numeric <op> EMatrix
    def initialize(n)
      @n = n
    end

    def * m # Numeric * EMatrix
      m * @n
    end
  end

  attr_reader :a, :m, :n

  # a : [ [] ]
  # m : Integer number of rows
  # n : Integer number of columns
  #
  # ([[1,2], [3,4]])
  # => [ 1 2 ]
  #    [ 3 4 ]
  # ([[1,2,3,4]])
  # => [ 1 2 3 4 ]
  # ([[1],[2],[3],[4]])
  # => [ 1 ]
  #    [ 2 ]
  #    [ 3 ]
  #    [ 4 ]
  # (1,2,3,4)
  # => [ 1 2 ]
  #    [ 3 4 ]
  def initialize(*args)
    if block_given? and (args.length == 2) || (args.length == 1 && args *= 2) # new(m, n) { |i,j| }
      @a = Array.new(args.first) { |i|
        Array.new(args.last) { |j|
          yield(i, j)
        }
      }
    elsif Array === args[0] && args.length == 1 && Array === args[0][0] # new([[a_ij],[],..])
      @a = args[0].to_a
    elsif args == args.flatten and !args.empty? # new(a, ...) regular matrix case
      sqrt_len = Math.sqrt(args.length)
      raise ArgumentError, 'Cannot create not regular matrix with this expression' unless sqrt_len.to_i == sqrt_len
      @a = Array.new(sqrt_len) { |i|
        args[i*sqrt_len, sqrt_len]
      }
    else
      raise ArgumentError, '[[]+] or (m, n=m) { |i,j| Numeric } or Numeric+ for regular'
    end
    @m, @n = @a.length, @a[0].length
  end

  class << self
    def [](*args)
      if args.all? { |arg| Array === arg }
        new([*args]) # Let's consider the outer [] as an Array
      else
        new(*args)
      end
    end

    def identity(n = 1)
      new(n) { |i,j|
        (i == j) ? 1 : 0
      }
    end
    alias :I :identity

    def random(n, range = -5..5)
      new(n) { rand(range) }
    end
  end

  def new(&block)
    EMatrix.new(@m, @n, &block)
  end

  def square?
    @m == @n
  end
  def regular?
    square? && determinant != 0
  end
  def singular?
    square? && determinant == 0
  end
  def dim?(o)
    o.is_a?(EMatrix) && @m == o.m && @n == o.n
  end

  def ==(o)
    o.is_a?(EMatrix) && o.a == @a
  end
  def dup
    EMatrix.new(to_a)
  end
  alias :clone :dup

  def row(r)
    EVector.new(*@a[r])
  end
  def col(c)
    EVector.new(*@a.map { |row| row[c] })
  end
  def set_row(r, v)
    @a[r] = v.to_a
    self
  end
  def set_col(c, v)
    v.each_with_index { |e, i|
      @a[i][c] = e
    }
    # @a.map! { |row| row[c] = v; row }
  end

  def diagonal # the main diagonal
    raise unless square?
    @m.times.map { |i| @a[i][i] }
  end

  def [](i, j)
    @a[i-1][j-1]
  end
  def []=(i, j, v)
    @a[i-1][j-1] = v
  end

  def each
    @a.each { |row| yield row }
  end

  def +@
    self
  end
  def -@
    new { |i,j| -@a[i][j] }
  end
  def + o
    raise "matrix have to be same dimensions" unless dim? o
    new { |i,j| @a[i][j] + o.a[i][j] }
  end
  def - o
    raise "matrix have to be same dimensions" unless dim? o
    new { |i,j| @a[i][j] - o.a[i][j] }
  end
  def * o
    case o
    when Numeric
      new { |i,j| @a[i][j] * o }
    when EMatrix
      raise "wrong dimensions" unless @n == o.m
      EMatrix.new(@m, o.n) { |i,j|
        @n.times.inject(0) { |vij,k|
          vij + @a[i][k] * o.a[k][j]
        }
      }
    end
  end
  def / n
    raise "#{self.class} can only be divided by a numeric value" unless n.is_a? Numeric
    new { |i,j| Rational(@a[i][j], n) }
  end

  # fast, exponentiation by squaring
  # Integer(0-99): 2*2:16250, 3*3:8200, 4*4:4100, 5*5:3500, 10*10:1000, 30*30:70
  def **(i)
    raise "i must be an Integer" unless i.is_a? Integer
    result = EMatrix.identity(@m)
    x = self.dup
    if i < 0
      x = inverse
      i = -i
    end
    until i == 0
      result *= x unless i.even?
      x *= x
      i /= 2
    end
    result
  end

  def exp(n) # EMatrix exponential
    result = copy = EMatrix.identity(@n)
    fact = 1
    1.upto(n) { |i| result += (copy*=self) / (fact*=i) }
    result
  end

  def trace
    diagonal.inject(:+)
  end

  def minor(r, c)
    EMatrix.new( to_a.tap { |a| a.delete_at(r) and a.each { |row| row.delete_at(c) } } ).determinant
  end

  def cofactor(r, c)
    (-1)**(r+c) * minor(r, c)
  end

  # These 2 don't want to work :(
  # def echelon2
  #   a = to_a
  #   a.each_with_index { |row,i|
  #     row.each_with_index { |_,j|
  #       # Find pivot in column j, starting in row i
  #       max_i = i
  #       for k in i...@m
  #         if a[k][j].abs > a[max_i][j].abs
  #           max_i = k
  #         end
  #       end
  #       if a[max_i][j] != 0
  #         # swap rows i and max_i, but do not change the value of i
  #         a[i], a[max_i] = a[max_i], a[i] # Now A[i,j] will contain the old value of A[max_i,j].
  #
  #         # divide each entry in row i by A[i,j]
  #         a[i] = (EVector[a[i]]/a[i][j]).to_a # a[i] = a[i].map { |e| Rational(e, a[i][j]).simplify }
  #         # Now A[i,j] will have the value 1.
  #         p "should be 1: #{a[i][j]}"
  #         for u in i...@m
  #           # subtract A[u,j] * row i from row u
  #           a[u] = (EVector[a[u]] - a[u][j] * EVector[a[i]]).to_a
  #           # Now A[u,j] will be 0, since A[u,j] - A[i,j] * A[u,j] = A[u,j] - 1 * A[u,j] = 0.
  #           p "should be O: #{a[u][j]} and #{a[i][j]} == 1"
  #         end
  #       end
  #     }
  #   }
  #   EMatrix.new(a)
  # end
  #
  # def echelon
  #   m = to_a
  #   l = 0 # lead
  #   @m.times { |r|
  #     if @n <= l
  #       return :bad1 # stop function
  #     end
  #     i = r
  #     while m[i][l] == 0
  #       i += 1
  #       if @m == i
  #         i = r
  #         l += 1
  #         if @n == l
  #           return :bad2 # stop function
  #         end
  #       end
  #     end
  #     #if i != r
  #     m[i], m[r] = m[r], m[i] # Swap rows i and r
  #     #end
  #     m[r] = (EVector[*m[r]] / m[r][l]).to_a # m[r].map! { |e| Rational(e, m[r][l]).simplify } # Divide row r by M[r, l]
  #     @m.times { |ii|
  #       if ii != r
  #         m[ii] = (EVector[*m[ii]] - m[i][l]*EVector[*a[r]]).to_a # Subtract M[i, l] multiplied by row r from row i
  #       end
  #     }
  #     l += 1
  #   }
  #   EMatrix.new(m)
  # end
  # alias :reduced :echelon

  def triangular # Triangularize a matrix (bottom-left empty, so it echelons it)
    a = to_a
    @m.times { |i|
      j = a[i].index { |e| e != 0 } #TODO
      raise 'Not possible to make it triangular' if j.nil? #or j != i

      if i != j
        # invert col(i) <-> col(j)
        @m.times { |r| a[r][i], a[r][j] = a[r][j], a[r][i] }
        # make row(i) signs opposite cause we exchanged two columns
        a[i].map! { |e| -e }
      end

      # Scaling to have a 1 as head coef # We can't for det
      # a[i] = (EVector[a[i]]/a[i][j]).to_a

      (i+1...@m).each { |k|
        v = Rational(a[k][i], a[i][i]).simplify
        #a[k] = (EVector[a[k]] - EVector[a[i]]*v).to_a
        a[k].each_index { |l|
          a[k][l] -= a[i][l] * v
        }
      }
    }
    EMatrix.new(a)
  end

  def determinant # 60*60 => 1.1s vs stdlib: 1.0s
    raise "determinant can only be computed on square EMatrix" unless square?
    m = @a
    case @m
    when 1
      + m[0][0]
    when 2
      + m[0][0] * m[1][1] - m[0][1] * m[1][0]
    when 3
      m0, m1, m2 = m
      + m0[0] * m1[1] * m2[2] - m0[0] * m1[2] * m2[1] \
      - m0[1] * m1[0] * m2[2] + m0[1] * m1[2] * m2[0] \
      + m0[2] * m1[0] * m2[1] - m0[2] * m1[1] * m2[0]
    when 4
      m0, m1, m2, m3 = m
      + m0[0] * m1[1] * m2[2] * m3[3] - m0[0] * m1[1] * m2[3] * m3[2] \
      - m0[0] * m1[2] * m2[1] * m3[3] + m0[0] * m1[2] * m2[3] * m3[1] \
      + m0[0] * m1[3] * m2[1] * m3[2] - m0[0] * m1[3] * m2[2] * m3[1] \
      - m0[1] * m1[0] * m2[2] * m3[3] + m0[1] * m1[0] * m2[3] * m3[2] \
      + m0[1] * m1[2] * m2[0] * m3[3] - m0[1] * m1[2] * m2[3] * m3[0] \
      - m0[1] * m1[3] * m2[0] * m3[2] + m0[1] * m1[3] * m2[2] * m3[0] \
      + m0[2] * m1[0] * m2[1] * m3[3] - m0[2] * m1[0] * m2[3] * m3[1] \
      - m0[2] * m1[1] * m2[0] * m3[3] + m0[2] * m1[1] * m2[3] * m3[0] \
      + m0[2] * m1[3] * m2[0] * m3[1] - m0[2] * m1[3] * m2[1] * m3[0] \
      - m0[3] * m1[0] * m2[1] * m3[2] + m0[3] * m1[0] * m2[2] * m3[1] \
      + m0[3] * m1[1] * m2[0] * m3[2] - m0[3] * m1[1] * m2[2] * m3[0] \
      - m0[3] * m1[2] * m2[0] * m3[1] + m0[3] * m1[2] * m2[1] * m3[0]
    else
      triangular.diagonal.inject(:*).simplify rescue 0 # det_cofactor
    end
  end
  def det_cofactor
    if @m == 1
      @a[0][0]
    elsif @m == 2 # for speed (2 times faster)
      @a[0][0]*@a[1][1]-@a[0][1]*@a[1][0]
    elsif @m == 3 # for speed (2 times faster)
      @a[0][0]*@a[1][1]*@a[2][2] + @a[0][1]*@a[1][2]*@a[2][0] + @a[0][2]*@a[1][0]*@a[2][1] - @a[0][0]*@a[1][2]*@a[2][1] - @a[0][1]*@a[1][0]*@a[2][2] - @a[0][2]*@a[1][1]*@a[2][0]
    else
      @m.times.inject(0) { |det, c|
        if @a[0][c] == 0
          det
        else
          det + (-1)**c * @a[0][c] * EMatrix.new( to_a.tap { |a| a.delete_at(0) and a.each { |row| row.delete_at(c) } } ).det_cofactor
        end
      }
    end
  end
  alias :det :determinant

  def cofactor_matrix # The cofactor matrix
    new { |i,j| cofactor(i,j) }
  end
  alias :comatrix :cofactor_matrix

  # adjugate or classical adjoint
  def adjugate
    cofactor_matrix.transpose
  end
  alias :adj :adjugate

  def inverse
    raise "determinant must not be 0" if (d = determinant) == 0
    adjugate / d
  end
  alias :inv :inverse

  # Integer(0-99): 100*100:287
  def transpose
    EMatrix.new(@n, @m) { |i,j| @a[j][i] }
  end

  # Linear Systems
  def diagonalizable?
    raise ArgumentError unless square?
    # 1) det(A-λ*I) != 0
    λ = 1
    (self - λ * EMatrix.I(@n)).det != 0
    #TODO
  end

  def Cramer(*args)
    return EMatrix.new(@a.transpose[0...-1].transpose).send(__method__, *(col(-1).to_a+args)) if @n == @m+1
    verbose = args.delete(:silent).nil?
    sol = []
    if regular? && args.length == @m
      d = determinant
      puts "|A| = #{d}" if verbose
      @m.times { |j|
        a = to_a
        a.each_with_index { |row, i| row[j] = args[i] }
        rd =  EMatrix.new(a).determinant
        puts "|A#{j+1}| = #{rd}" if verbose
        sol << Rational(rd,d).simplify # (rd%d == 0 ? rd/d : Rational(rd,d))
      }
      sol.each_with_index { |s, i| puts "x#{i+1} = #{s}" } if verbose
    else
      raise ArgumentError, "You must set the values"
    end
    sol
  end
  def Cramer_silent(*args)
    Cramer(*args, :silent)
  end

  # Allow self.l2 -= l3
  def do(&block)
    instance_eval(&block)
    self
  end

  def method_missing(meth, *args, &block)
    if meth =~ /^(r|c)(\d+)(=?)$/
      i = $2.to_i - 1
      raise "only positive (l/c) i" if i < 0
      if args.length == 0 and $3.empty? # ri, ci
        $1 == 'r' ? row(i) : col(i)
      elsif args.length == 1 and !$3.empty? # ri=, ci=
        $1 == 'r' ? set_row(i, args[0]) : set_col(i, args[0])
      end
    else
      super
    end
  end

  #Conversion
  def coerce(other)
    if Numeric === other
      [EMatrix::Scalar.new(other), self]
    else
      raise TypeError, ": #{self.class} can't be coerced into #{other.class}"
    end
  end

  def simplify
    @a.map! { |row| row.map! { |e| e.respond_to?(:simplify) ? e.simplify : e } }
  end

  def inspect
    simplify
    max_len = @a.flatten.map { |e|
      raise "You have a EVector in a #{self.class} cell !" if EVector === e
      e.to_s.length
    }.max
    @a.map { |row|
      "["+row.map { |e| e.to_s.rjust(max_len) }.join(", ")+"]"
    }.join("\n")
  end
  alias :to_s :inspect

  def to_a
    @a.map(&:dup)
  end
end

if __FILE__ == $0
  require "minitest/autorun"
  $VERBOSE = true
  class TestMatrix < MiniTest::Unit::TestCase
    def setup
      @a = EMatrix[
        [1, 2],
        [3, 4]
      ]
      @b = EMatrix[
        [-1,  2],
        [-2, -3]
      ]

      # [ 1, -1,  2]
      # [ 2,  1, -1]
      # [ 1, -2,  1]
      @m = EMatrix[1,-1,2,2,1,-1,1,-2,1]

      @m7 = EMatrix.new [
        [-3, -4, -2,  4,  0,  0, -3],
        [ 1,  0,  4,  2,  0,  2,  4],
        [ 0,  0, -3,  4,  0,  1, -4],
        [ 3,  0,  1,  4, -2,  0,  0],
        [ 2,  0,  4, -4,  0,  2,  0],
        [-1,  2,  2,  2, -1,  2,  1],
        [ 3,  0, -4,  0,  2,  0, -2]
      ]

      @m4 = EMatrix.new(
      19,5,1,0,
      -30,-6,0,1,
      1,1,1,1,
      -1,1,-1,1
      )
      @m3 = EMatrix.new(
      -1,2,5,
      1,2,3,
      -2,8,10
      )
      @m3_2 = EMatrix.new(
      18,2,-8,
      2,-3,6,
      5,12,-11
      )
      @m2 = EMatrix.new(
      5,8,
      9,1
      )
      @m1 = EMatrix.new(5)

      @m23 = EMatrix.new([[6,8,2],[-5,3,-1]])

      @singular = EMatrix[
        [1, 2],
        [2, 4]
      ]
    end

    def test_cramer
      assert_equal [2, -9, -3, 9], @m4.Cramer_silent(-10,3,-1,1)
    end

    def test_det
      assert_equal 5, @m1.determinant
      assert_equal(-67, @m2.determinant)
      assert_equal 32, @m3.determinant
      assert_equal 48, @m4.determinant
      assert_equal 3840, @m7.determinant
      assert_equal 0, @singular.det
      assert_equal(-8, @m.det)
    end

    def test_add
      assert_equal(@m4*2, @m4+@m4)
    end
    def test_mul
      assert_equal EMatrix[-5, -4, -11, -6], @a * @b
      assert_equal EMatrix.new(4) { |i,j| @m4.a[i][j]*7 },@m4*7
      assert_equal EMatrix.new(11,52,-35,37,32,-29,30,92,-46),@m3*@m3_2
    end
    def test_div
      assert_equal EMatrix.new(4) { |i,j| @m4.a[i][j]/2.0 }, @m4/2
    end
    def test_power
      assert_equal @m*@m, @m**2
      assert_equal EMatrix.new(-53,478,601,-47,378,475,-126,1076,1366),@m3**3
      assert_equal EMatrix.identity(3),@m3**0
      assert_equal @m3.inv**2,@m3**-2
    end
    def test_transpose
      assert_equal EMatrix.new(3,2) { |i,j| @m23.a[j][i] }, @m23.transpose
    end
    def test_inv
      assert_equal EMatrix.identity(3), @m3.inv*@m3
      assert_equal @m3.inv, @m3**-1
    end

    def test_li_ci
      assert_equal EVector[1,-1,2], @m.r1
      assert_equal EVector[-1,1,-2], @m.c2
    end

    def test_do
      @m.do { self.r1 -= r2*2 }
      assert_equal EVector[-3, -3, 4], @m.r1

      @m.tap { |m| m.c3 += m.c2 }
      assert_equal EVector[1, 0, -1], @m.c3

      @m.do { |m| m.r2 -= m.r3*0 }
      assert_equal EVector[2, 1, 0], @m.r2
    end

    def test_properties_adj
      n = 3 # rand(5..7)
      a, b, i = EMatrix.random(n), EMatrix.random(n), EMatrix.I(n)

      assert_equal i, i.adj
      assert_equal((a*b).adj, b.adj*a.adj)
      assert_equal a.adj.transpose, a.transpose.adj

      assert_equal a.det**(n-1), a.adj.det
    end

    def test_coerce
      assert_equal @m*7, 7*@m
      assert_raises(NoMethodError) { 7 + @m }
      assert_raises(NoMethodError) { 7 - @m }
      assert_raises(NoMethodError) { 7 / @m }
    end

    instance_methods(false).grep(/^test_/).each { |m|
      alias :"_#{m}" :"#{m}"
      define_method(m) { |*args|
        puts m
        send(:"_#{m}", *args)
      }
    }
  end
end

# p EMatrix[
# [-3,  5,  5],
# [ 3, -5, -3],
# [ 1, -5,  1]
# ].triangular

# p EMatrix.random(45).triangular.diagonal.inject(:*)
# p EMatrix.random(8).det_cofactor