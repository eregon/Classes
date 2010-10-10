require_relative "point"
require_relative "polynomial"

module Interpolation
  extend self

  # Polynomial interpolation of Lagrange
  # [Point.new(x,y)] points
  def Lagrange(p)
    p.each_index.inject(0) { |r,k|
      # t = Polynomial.new(Rational(p[k].y))
      t = Polynomial.new(p[k].y) # We don't want so much precision if we start with Float
      p.each_index { |i|
        diff = p[k].x - p[i].x
        unless diff.zero? # i == k or diff.zero?
          # t *= Polynomial.new( 1.0 / diff, -p[i].x / diff.to_f ) # Float are evil !
          t *= Polynomial.new( Rational(1, diff), Rational(-p[i].x, diff) ) # Rational are great !
        end
      }
      r + t
    }.simplify
  end
end

if __FILE__ == $0
  require 'minitest/autorun'
  class PolynomialTest < MiniTest::Unit::TestCase
    def test_interpolation_lagrange_wikipedia
      points = [Point.new(-9, 5), Point.new(-4, 2), Point.new(-1, -2), Point.new(7, 9)]
      # 0.021117424242424243x^3 + 0.20397727272727273x^2 - 0.7569128787878785x - 2.9397727272727274
      poly = Interpolation.Lagrange(points) # 23/10560x^3 + 359/1760x^2 - 7993/10560x - 2587/880
      assert_equal points.map(&:y), points.map { |p| poly & p.x }
    end

    def test_interpolation_lagrange1
      # 3x - 2
      points = [Point.new(2,4), Point.new(4,10), Point.new(5,13)]
      poly = Interpolation.Lagrange(points)
      assert_equal points.map(&:y), points.map { |p| poly & p.x }
    end

    def test_interpolation_lagrange2
      # x^2 + 1
      points = [Point.new(0,1), Point.new(2,5), Point.new(4,17)]
      poly = Interpolation.Lagrange(points)
      assert_equal points.map(&:y), points.map { |p| poly & p.x }
    end

    def test_interpolation_lagrange_my
      points = [Point.new(-2,0), Point.new(-1,1), Point.new(0,2), Point.new(1,1),Point.new(2,0)]
      poly = Interpolation.Lagrange(points) # 1/6x^4 - 7/6x^2 + 2
      assert_equal points.map(&:y), points.map { |p| poly & p.x }
    end

    def test_interpolation_lagrange_rosetta
      x = [0, 1,  2,  3,  4,  5,   6,   7,   8,   9,  10]
      y = [1, 6, 17, 34, 57, 86, 121, 162, 209, 262, 321]
      points = x.each_index.map { |i| Point.new(x[i],y[i]) }
      poly = Interpolation.Lagrange(points) # 3x^2 + 2x + 1
      assert_equal points.map(&:y), points.map { |p| (poly & p.x).round } #OK
    end

    def test_interpolation_lagrange_rand
      n = 20
      p1 = Polynomial.new(n) { 5-rand(10) }
      points = n.times.map { |i| x = 10*(i-5)-rand(10); Point.new(x, p1 & x) }
      poly = Interpolation.Lagrange(points)
      assert_equal points.map { |p| p.y }, points.map { |p| poly & p.x }
    end
  end
end