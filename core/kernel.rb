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
  require "rspec"

  describe "Kernel#rand" do
    it "make easier to create random numbers" do
      # prng.rand(5..9)  # => one of [5, 6, 7, 8, 9]
      # prng.rand(5...9) # => one of [5, 6, 7, 8]
      # prng.rand(5.0..9.0) # => between 5.0 and 9.0, including 9.0
      # prng.rand(5.0...9.0) # => between 5.0 and 9.0, excluding 9.0

      100.times {
        a, b = 5, 9
        c, d = 5.0, 9.0
        ab, awb = (a..b), (a...b)
        cd, cwd = (c..d), (c...d)
        ab.should include rand(ab)
        awb.should include rand(awb)
        cd.should include rand(cd)
        cwd.should include rand(cwd)
      }
    end
  end
end