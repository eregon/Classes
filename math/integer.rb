class Integer
  # Compute the factorial
  # Fast (32000! in 1s)
  def !
    raise "Factorial: n has to be >= 0, but was #{self}" unless self >= 0
    self == 0 ? 1 : (1..self).inject { |m, o| m * o }
  end
end