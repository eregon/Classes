# from "Programming Ruby"

class Roman
  MAX_ROMAN = 4999
  FACTORS = [
    ["M", 1000], ["CM", 900], ["D",  500], ["CD", 400],
    ["C",  100], ["XC",  90], ["L",   50], ["XL",  40],
    ["X",   10], ["IX",   9], ["V",    5], ["IV",   4],
    ["I",    1]
  ]

  attr_reader :value
  protected :value

  def initialize(value)
    raise "Roman values must be > 0 and <= #{MAX_ROMAN}" unless value > 0 and value <= MAX_ROMAN
    @value = value.to_int
  end

  def Roman.from_s(str)
    str = str.to_s
    raise "wrong string(#{str}). Only /^[ixcmvld]+$/i" unless str =~ /^[ixcmvld]+$/i
    str.upcase!
    value = 0
    for code, factor in FACTORS
      if pos = (str =~ /^((?:#{code})+)/)
        value += factor * ($1.length/code.length)
        str = $'
      end
    end
    Roman.new(value)
  end

  def ==(o)
    o.class == Roman && @value == o.value
  end

  def coerce(o)
    case o
    when Integer === o
      [ o, @value ]
    else
      [ Float(o), Float(@value) ]
    end
  end

  def +(o)
    if Roman === o
      o = o.value
    elsif Fixnum === o && (o + @value) < MAX_ROMAN
      Roman.new(@value + o)
    else
      x, y = o.coerce(@value)
      x + y
    end
  end

  def to_i
    @value
  end
  alias :to_int :to_i

  def inspect
    value = @value
    roman = ""
    for code, factor in FACTORS
      count, value = value.divmod(factor)
      roman << (code * count)
    end
    roman
  end
  alias :to_s :inspect

  def to_s_inject
    FACTORS.inject(["", @value]) { |(answer, number), (roman, arabic)|
      [ answer + roman * (number / arabic), number % arabic ]
    }.first
  end
end

# include this to allow "iv #=> IV"
module RomanMixin
  def method_missing(name, *args)
    if name.to_s =~ /^[ixcmvld]+$/
      Roman.from_s(name.to_s)
    else
      super
    end
  end
end

if __FILE__ == $0
  include RomanMixin
  puts "IV: #{iv.to_s_inject}"
  puts "4949 #{Roman.new(4949)}"
end
