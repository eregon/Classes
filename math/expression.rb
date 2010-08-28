=begin
Math Expression
Functions
Derivee
Integrale
=end

=begin
  Symbol name
  String deriv: derivative
  String integ: integral
=end
module MathExp
  class Function
    attr_reader :name, :deriv, :integ
    def initialize(name, of = nil, deriv = '', integ = '')
      @name = name.to_sym
      of = MathExp.x if of.nil?
      @of = of
      @deriv = deriv
      @integ = integ
    end
    def param param
      @param = param
      self
    end

    def derivative
      return @deriv if @of.name == :x
      @deriv.sub(/(x)/, @of.to_s)+"*#{@of.derivative}"
    end

    def inspect
      return 'x' if @name == :x

      if [:ln].include? @name
        if @of.name == :x
          of = ' x'
        else
          of = "(#{@of})"
        end
      else
        if [:x, :sq,:cb,:pow, :sqrt,:cbrt, :sin,:cos].include? @of.name
          of = "#{@of}"
        else
          of = "(#{@of})"
        end
      end

      if [:sq, :cb, :pow].include? @name
        case @name
        when :sq
          "#{of}^2"
        when :cb
          "#{of}^3"
        when :pow
          "#{of}^#{@param}"
        end
      elsif [:sqrt,:cbrt, :sin,:cos].include? @name
        "#{@name}(#{of})"
      elsif [:ln].include? @name
        "#{@name}#{of}"
      elsif @name == :e
        "e^#{of}"
      end
    end
    alias :to_s :inspect
  end
end
module MathExp
  class Function

    def self.x()
      Function.new(:x, 'x', '1', 'x^2/2')
    end

    def self.sq(x = nil) Function.new(:sq, x, '2x', 'x^3/3') end
    def self.cb(x = nil) Function.new(:cb, x, '3x^2', 'x^4/4') end

    def self.sqrt(x = nil) Function.new(:sqrt, x, '1/(2*sqrt(x))') end
    def self.cbrt(x = nil) Function.new(:cbrt, x, '1/(3*cbrt((x)^2))') end
    def self.pow(x, e)
      Function.new(:pow, x, "#{e}x^#{e-1}", "#x^#{e+1}/#{e+1}").param(e)
    end

    def self.ln(x = nil) Function.new(:ln, x, '1/x') end
    def self.e(x = nil) Function.new(:e, x, 'e^(x)') end

    def self.sin(x = nil) Function.new(:sin, x, 'cos(x)') end
    def self.cos(x = nil) Function.new(:cos, x, '(-sin(x))') end

  end
end