module Kernel
  alias :_rand :rand
  def rand(val=0)
    if Range === val
      b, e = val.begin, val.end
      e += 1 if !val.exclude_end? and Integer === e
      if Integer === b and Integer === e
        b + rand(e-b)
      elsif Float === b and Float === e
        # Doesn't work to include range with end float included
        b + rand * (e-b)
      else
        raise ArgumentError
      end
    else
      _rand(val)
    end
  end
end

if __FILE__ == $0
  require "test/unit"

  class TestKernel < Test::Unit::TestCase
    def test_rand
      # prng.rand(5..9)  # => one of [5, 6, 7, 8, 9]
      # prng.rand(5...9) # => one of [5, 6, 7, 8]
      # prng.rand(5.0..9.0) # => between 5.0 and 9.0, including 9.0
      # prng.rand(5.0...9.0) # => between 5.0 and 9.0, excluding 9.0

      100.times {
        a, b = 5, 9
        c, d = 5.0, 9.0
        r = 0
        ab = (a..b)
        awb = (a...b)
        cd = (c..d)
        cwd = (c...d)
        assert ab.include?(r=rand(ab))
        p r if r == b
        assert awb.include?(rand(awb))
        assert cd.include?(r=rand(cd))
        p r if r == d
        assert cwd.include?(rand(cwd))
      }
    end
  end
end