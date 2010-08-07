# A little #to_proc craziness
# Ideas came from many places
# Mainly http://rbjl.net/29-become-a-proc-star

class Array
  def to_proc
    if Array === first
      if size == 1
        procs = first.map(&:to_proc)
        Proc.new { |obj|
          procs.map { |sub| sub[obj] }
        }
      else
        procs = map(&:to_proc)
        Proc.new { |obj|
          procs.inject(obj) { |result, sub|
            sub[result]
          }
        }
      end
    else
      Proc.new { |obj| obj.send(*self) }
    end
  end
end

class Hash
  def to_proc
    procs = self.each_pair.with_object({}) { |(filter, map), procs|
      procs[filter] = map.respond_to?(:to_proc) ? map.to_proc : Proc.new { map }
    }
    filters = self.keys
    Proc.new { |obj|
      if filter = filters.find { |filter| filter === obj }
        procs[filter][obj]
      else
        obj
      end
    }
  end
end

if __FILE__ == $0
  require "rspec"

  describe "Array#to_proc" do
    it "should behaves like a full block" do
      ary = [*1..5]

      ary.map(&[:*, 2]).should ==
      ary.map { |i| i*2 }

      ary.map(&[:to_s]).should ==
      ary.map { |i| i.to_s }

      ary = %w[f,oo ba,r]

      ary.map(&[:split, ',']).should ==
      ary.map { |i| i.split ',' }
    end

    it "should accepts nested Arrays for chaining" do
      ary = [*1..5]
      ary.map(&[[:*,2],[:+,4]]).should ==
      ary.map { |i| i*2 + 4 }
    end

    it "should return an Array of n results when calling with a single nested Array of n elements" do
      ary = [*1..5]
      ary.map(&[[:to_s, :to_f]]).should ==
      ary.map { |i| [i.to_s, i.to_f] }

      ary.map(&[[[:to_s, 2], :to_f]]).should ==
      ary.map { |i| [i.to_s(2), i.to_f] }
    end
  end

  describe "Hash#to_proc" do
    it "a Hash should act like a selective map" do
      ary = [1, "2", :"3"]
      ary.map(&{ 1 => [:*,3], String => :to_i, /3/ => 4 }).should == [3, 2, 4]
    end
  end
end
