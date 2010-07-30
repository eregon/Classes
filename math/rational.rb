class Rational < Numeric
  def simplify
    denominator == 1 ? numerator : self
  end
end