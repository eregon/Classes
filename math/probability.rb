require_relative 'integer'

module Probability
  module_function
  def C x, n
    n.! / (x.! * (n-x).!)
  end

  module P
    module_function

    # Binomial distribution
    def binomial(x, n, p)
      C(x,n) * p**x * (1-p)**(n-x)
    end

    # Geometric distribution
    def geometric(x, p)
      p * (1-p)**(x-1)
    end

    # Negative binomial distribution for integers
    def pascal(x, k, p)
      C(k-1,x-1) * p**k * (1-p)**(x-k)
    end
  end

  module F
    module_function

    # def binomial(x, n, p)
    #   (0..x).inject(0) { |sum, xi| sum + P.binomial(xi, n, p) }
    # end
    def method_missing(meth, *args, &block) # right?
      x, rest = args.first, args[1..-1]
      (0..x).inject(0) { |sum, xi| sum + P.send(meth, xi, *rest) }
    end

    def geometric(x, p)
      1 - (1-p)**x
    end
  end
end

if __FILE__ == $0
  include Probability
  # 3-17
  p, n = 0.2, 10
  require_relative '../erray'
  puts (n+1).times.map { |x|
    [x, P.binomial(x, n, p), F.binomial(x, n, p)].map { |n| Float === n ? n.round(4) : n }
  }.transpose.to_table

  p F.geometric(2,0.6)
end

