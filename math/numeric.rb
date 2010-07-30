class Numeric
  def simplify
    self
  end
  def derivative(n = 0)
    0
  end
  def integral(n = 0)
    self == 0 ? 0 : Polynomial.new(self, 0)
  end
end