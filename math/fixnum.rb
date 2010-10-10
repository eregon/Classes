class Fixnum
  # Lazy evaluation for: n * lambda { do_something_expensive }
  # Short-circuit if n == 0 (and then n is of course a Fixnum)
  # This is of course a very bad idea to re-define Fixnum * ...
  # alias :_old_mul :*
  # def * o
  #   if Proc === o
  #     return 0 if self == 0
  #     self * o.call
  #   else
  #     _old_mul(o)
  #   end
  # end
end

if __FILE__ == $0
  require "minitest/autorun"
  require "benchmark"
  class TestFixnum < MiniTest::Unit::TestCase
    def test_mul
      assert Benchmark.realtime { 2 * 0 * lambda { sleep 2; 1 } } < 0.1
      assert_equal 0, 2 * 0 * lambda { sleep 2; 1 }
      assert_equal 6, 2 * lambda { 3 }
    end
  end
end