#require 'rational'
#require 'bigdecimal'
#require 'bigdecimal/util' # allow .to_d for Float,Rationnal and String

#$: << File.dirname(__FILE__)+'/math'
Dir[File.join(File.dirname(__FILE__), File.basename(__FILE__, '.rb'), '*.rb')].each { |f| require f }

module Math
  def P(*args)
    Polynomial.new(*args)
  end
  module_function :P
end

# Allow conversion of true, false into Fixnum

module Boolean
  def coerce(other)
    if other.kind_of? Numeric
      [other, to_i]
    else
      [other, self]
    end
  end

  def to_i
    self ? 1 : 0
  end
end
class TrueClass
  include Boolean
end
class FalseClass
  include Boolean
end

if __FILE__ == $0
  require "test/unit"

  class TestMath < Test::Unit::TestCase
    def test_boolean_coerce
      assert_equal(3, 2 + true)
      assert_equal(2, 2 - false)
      assert_equal(0, 3 * false)
      assert_equal(3, 3 / true)
      assert_equal(1, Math::E**false)
    end
  end
end