require_relative 'polynomial'

class Equation
  def initialize(f, verbose = false)
    @f = f
    @v = verbose
  end

  def resolve
    case @f.degree
    when 1
      [ -@f[0] / @f[1] ]
    when 2
      Equation2d.new(@f).resolve
    when 3
      Equation3d.new(@f).resolve
    else
      newton(0, 4)
    end
  end

  # Dichotomie
  def binary_search(lower, upper, p)
    return binary_search_v(lower, upper, p) if @v
    raise 'No root found' if lower > upper
    middle = (lower+upper)/2.0
    case @f.run(middle).round(p) <=> 0
    when -1 # <
      binary_search(middle,upper,p)
    when 0 # =
      middle.round(p)
    when 1 # >
      binary_search(lower,middle,p)
    end
  end
  def binary_search_v(lower, upper, p)
    @i ||= 0
    @i += 1
    raise 'No root found' if lower > upper
    middle = (lower+upper)/2.0
    case @f.run(middle).round(p) <=> 0
    when -1 # <
      binary_search_v(middle,upper,p)
    when 0 # =
      puts "#{@i} iterations"
      middle.round(p)
    when 1 # >
      binary_search_v(lower,middle,p)
    end
  end

  # Newton
  def newton(x0, p, max = 10000)
    return newton_v(x0, p, max) if @v
    # Numeric x0 : first x given
    # Integer p : precision
    # Integer max : max iterations
    d = @f.derivative
    i = 0
    before, last = x0.to_f, nil
    begin
      i += 1
      x = before
      x += 0.001 while d.run(x) == 0 # Avoid dv = 0
      last =  x - @f.run(x).to_f/d.run(x)
      raise 'No root found' if i > max
      before, last = last, before
    end until before.round(p) == last.round(p)
    before.round(p)
  end
  def newton_v(x0, p, max = 10000)
    # Numeric x0 : first x given
    # Integer p : precision
    # Integer max : max iterations
    d = @f.derivative
    i = 0
    results = [x0.to_f]

    begin
      i += 1
      x = results[-1]
      x += 0.001 while d.run(x) == 0 # Avoid dv = 0
      results << x - @f.run(x)/d.run(x).to_f
      raise 'No root found' if i > max
    end until results[-2].round(p) == results[-1].round(p)

    puts "Root: x#{i-1} = #{results[-2].round(p)}"
    puts "Found in #{i} iterations"
    results.each_with_index { |result, j| puts "x#{j} = #{result.round(p+1)}" }

    results[-2].round(p)
  end
end

class Equation2d
  # Polynomial(degree:2) p
  # ax^2 + bx + c = 0
  def initialize(*args)
    if(args[0].is_a? Polynomial)
      @p = args[0]
    elsif(args.length == 3)
      @p = Polynomial.new(args)
    end
  end
  def ro
    @p[1]**2 - 4*@p[0]*@p[2]
  end
  def resolve
    r = ro
    if r < 0
      []
    elsif r == 0
      [ -@p[1]/2/@p[2] ]
    elsif r > 0
      [ (-@p[1]-Math.sqrt(r))/2/@p[2], (-@p[1]+Math.sqrt(r))/2/@p[2] ]
    end
  end
  def factorize
    n = (roots = resolve).length
    if n == 2
      [ Polynomial.new(@p[2], -roots[0]*@p[2]), Polynomial.new(1, -roots[1]) ]
    elsif n == 1
      [ Polynomial.new(@p[2]**0.5, -roots[0]*@p[2]**0.5), Polynomial.new(@p[2]**0.5, -roots[0]*@p[2]**0.5) ]
    else
      @p
    end
  end
end
class Equation3d
  # Polynomial(degree:3) p
  # ax^3 + bx^2 + cx + d = 0
  def initialize(*args)
    if(args[0].is_a? Polynomial)
      @p = args[0]
    elsif(args.length == 4)
      @p = Polynomial.new(*args)
    end
  end
  def discriminant
    #4 b3 d - b2 c2 + 4a c3 - 18abcd + 27 a2 d2
    4*@p[2]**3 * @p[0] \
    - @p[2]**2 * @p[1]**2 \
    + 4*@p[3] * @p[1]**3 \
    - 18 * @p[3] * @p[2] * @p[1] * @p[0] \
    + 27 * @p[3]**2 * @p[0]**2
  end
  def resolve
    # Method of Cardan
    polynom = @p / @p[3].to_f
    a, b, c = polynom[2].to_f, polynom[1].to_f, polynom[0].to_f
    y = Polynomial.new(1, a/3)
    polynom_y = y**3 + a*y**2 + b*y + c
    p, q = polynom_y[1], polynom_y[0]
    d = 4*p**3+27*q**2 # discriminant
    if d > 0
      sqrt = Math.sqrt( (q/2)**2 + (p/3)**3 )
      u = ( -q/2 + sqrt )**(1.0/3)
      v = ( -q/2 - sqrt )**(1.0/3)
      [u+v - a/3]
    elsif d == 0
      [3*q/p, -3*q/p, -3*q/p].sort
    elsif d < 0
      # GNU Scientific Library
      # not found how to do with Cardan
      polynom = @p / @p[3]
      a, b, c = polynom[2].to_f, polynom[1].to_f, polynom[0].to_f
      q = ( a**2 - 3*b ) / 9
      r = ( 2*a**3 - 9*a*b + 27*c ) / 54
      [
        -2*q**0.5 * Math.cos(Math.acos(r / q**(1.5))/3 ) - a/3,
        -2*q**0.5 * Math.cos( (Math.acos(r/ q**(1.5)) + 2*Math::PI)/3) - a/3,
        -2*q**0.5 * Math.cos( (Math.acos(r/ q**(1.5)) - 2*Math::PI)/3) - a/3
      ].sort
    end
  end
  def factorize
    roots = resolve
    case roots.length
    when 1
      [ Polynomial.new(1, -roots[0]), @p % roots[0] ]
    when 2
      [ Polynomial.new(1, -roots[0]), \
      Polynomial.new(1, -roots[1]), \
      (@p % roots[0]) % roots[1] ]
    when 3
      [ Polynomial.new(1, -roots[0])*@p[3], \
      Polynomial.new(1, -roots[1]), \
      Polynomial.new(1, -roots[2]) ]
    else
      @p
    end
  end
end

class Polynomial
  def resolve
    Equation.new(self).resolve
  end
  def factorize
    case @degree
    when 2
      Equation2d.new(self).factorize
    when 3
      Equation3d.new(self).factorize
    when 4
      Equation4d.new(self).factorize
    else
      [ Polynomial.new(@coef) ]
    end
  end
end