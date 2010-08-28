Dir[File.join(File.dirname(__FILE__), File.basename(__FILE__, '.rb'), '*.rb')].each { |f| require f }

module Math
  def P(*args)
    Polynomial.new(*args)
  end
  module_function :P
end

# Allow conversion of true, false into Fixnum

module Boolean
  def coerce other
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
end unless TrueClass.include? Boolean
class FalseClass
  include Boolean
end unless FalseClass.include? Boolean

if __FILE__ == $0
  require "rspec"
  describe Math do
    it "coerce booleans" do
      (2 + true).should == 3
      (2 - false).should == 2
      (3 * false).should == 0
      (3 / true).should == 3
      (Math::E**false).should == 1
    end
  end
end
