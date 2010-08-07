# Analyse arguments given to a method(*args)
#
# Exemple:
# def m(*args)
#   case args
#     when ARGS[Complex]
#       m(Complex.new(1,1))
#     when ARGS[Integer, Boolean]
#       m(2, true)
#     when ARGS[[Numeric, Float], String]
#       m([1, 3.14], "Hello World!")
#     when ARGS[[[Integer, Integer],[Float, Rational     ]]]
#       m(      [[1      , 2      ],[3.0  , Rational(1,2)]])
#   end
# end

module Boolean; end
class FalseClass; include Boolean; end
class TrueClass;  include Boolean; end

class ARGS
  def initialize(*constraints)
    @constraints = constraints
  end

  def ARGS.[](*constraints)
    ARGS.new(*constraints)
  end

  def match?(args)
    return false unless @constraints.length == args.length
    @constraints.each_with_index { |constraint, i|
      case constraint
      when Module
        unless args[i].is_a?(constraint)
          return false
        end
      when Array
        unless args[i].is_a?(Array) && ARGS[*constraint].match?(args[i])
          return false
        end
      end
    }
    true
  end

  def ===(args)
    match?(args)
  end
end
