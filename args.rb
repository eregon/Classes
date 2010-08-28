module Boolean end
class TrueClass
  include Boolean
end unless TrueClass.include? Boolean
class FalseClass
  include Boolean
end unless FalseClass.include? Boolean

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
class ARGS
  def initialize *constraints
    @constraints = constraints
  end

  def ARGS.[] *constraints
    ARGS.new *constraints
  end

  def match? args
    return false unless @constraints.length == args.length
    @constraints.zip(args) { |constraint, arg|
      case constraint
      when Module
        return false unless arg.is_a? constraint
      when Array
        return false unless arg.is_a?(Array) and ARGS.new(*constraint).match?(arg)
      end
    }
    true
  end

  alias :=== :match?
end

if __FILE__ == $0
  require 'rspec'
  describe ARGS do
    it 'analyse one argument' do
      ARGS[Complex].match?([2.i]).should be_true
      ARGS[Complex].match?([2]).should be_false
    end
    it 'handle multiple arguments' do
      ARGS[Integer, Boolean].match?([2,true]).should be_true
      ARGS[Integer, Boolean].match?([2,nil]).should be_false
      ARGS[Integer, Boolean].match?([2.i,true]).should be_false
    end
    it 'handle nested arguments (Array)' do
      ARGS[[Numeric, Float], String].should be_match [[1, 3.14], "Hello World!"]
      ARGS[[Numeric, Float], String].should_not be_match [[1, 3], "Hello World!"]
    end
    it 'really handle nested' do
      ARGS[[[Integer, Integer],[Float, Rational]]].should be_match [[[1, 2],[3.0, Rational(1,2)]]]
      ARGS[[[Integer, Integer],[Float, Rational]]].should_not be_match [[[1, 2],[3.0, 1.2]]]
    end
  end
end
