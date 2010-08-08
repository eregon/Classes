module Enumerable
  def with_other enum
    return enum_for(:with_other, enum) unless block_given?
    enum = enum.to_enum unless Enumerator === enum
    each { |*e|
      f = begin
        enum.next
      rescue StopIteration
        nil
      end
      args = e.size > 1 ? [e] << f : e << f # [[[1, 2], 3], 4] => (((a, b), c), d)
      yield(*args)
    }
  end

  def with_other_flat enum
    return enum_for(:with_other_flat, enum) unless block_given?
    enum = enum.to_enum unless Enumerator === enum
    each { |*e|
      f = begin
        enum.next
      rescue StopIteration
        nil
      end
      yield(*e, f) # [1, 2, 3, 4] => (a, b, c, d)
    }
  end
end

if __FILE__ == $0
  require "rspec"
  describe "Enumerable#with_other" do
    it "should iterate with other" do
      a, b = [1,2,3], [4,5,6]
      to_yield = a.zip(b)

      a.each.with_other(b) { |e,f|
        [e, f].should == to_yield.shift
      }
      to_yield.should be_empty
    end

    it "should iterate with smaller" do
      a, b = [1,2,3], [4,5]
      to_yield = a.zip(b)
      to_yield.size.should == 3
      to_yield[2][1].should be_nil

      a.each.with_other(b) { |e,f|
        [e, f].should == to_yield.shift
      }
      to_yield.should be_empty
    end

    it "should iterate with bigger" do
      a, b = [1,2,3], [4,5,6,7]
      to_yield = a.zip(b)
      to_yield.size.should == 3

      a.each.with_other(b) { |e,f|
        [e, f].should == to_yield.shift
      }
      to_yield.should be_empty
    end

    it "should work with Enumerator" do
      a, b = (1..5), (2..Float::INFINITY)
      to_yield = a.zip(b)

      a.each.with_other(b) { |e,f|
        [e, f].should == to_yield.shift
      }
      to_yield.should be_empty
    end

    it "should work in chain" do
      a, b = [1, 3, 5], [2, 4, 6]
      a.each.with_other(b).inject(0) { |sum, (e, f)| sum + e + f }.should == (1..6).reduce(:+)
      a.each.with_other(b).inspect.should == "#<Enumerator: #<Enumerator: [1, 3, 5]:each>:with_other([2, 4, 6])>"
    end

    it "should work with multiple calls" do
      a, b, c = [1, 4, 7], [2, 5, 8], [3, 6, 9]
      a.each.with_other(b).with_other(c).inject(0) { |sum, ((e, f), g)| sum + e + f + g }.should == (1..9).reduce(:+)
      a.each.with_other_flat(b).with_other_flat(c).inject(0) { |sum, (e, f, g)| sum + e + f + g }.should == (1..9).reduce(:+)
    end
  end
end
