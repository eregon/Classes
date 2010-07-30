require_relative '../erray'

class Stats1var
  def initialize(*data)
    @data = data.to_a.flatten
    @Q1, @median, @Q3 = nil, nil, nil
    @n = @data.length
    @min, @max = @data.min, @data.max
    @e = Array.new(@max-@min+1) { |i|
      @data.select { |e| e == i+@min }.length
    }
    @cumulative_e = @e.inject([]) { |memo, e| memo + [(memo.length == 0) ? e : e + memo[-1]] }
    @f = @e.map { |e| e.to_f/@n }
    @cumulative_f = @cumulative_e.map { |e| e.to_f/@n }
    @mode = []
    @variance = 0
    @e.each_with_index { |e, i|
      x = @min + i
      unless e == 0
        if @Q1.nil? && @cumulative_f[i] >= 0.25
          @Q1 = x
        elsif @median.nil? && @cumulative_f[i] >= 0.5
          @median = x
        elsif @Q3.nil? && @cumulative_f[i] >= 0.75
          @Q3 = x
        end
        @variance += e * x**2
      end
      @mode << x if e == @e.max
    }
    @mean = @data.inject(0) { |sum, d| sum + d }.to_f / @n
    @variance = @variance.to_f / @n - @mean**2
    @standard_deviation = Math.sqrt @variance
  end

  def inspect
    str = "Data: {#{@data.join ', '}}\n"
    str += "Population : #{@n} in [#{@min}, #{@max}]\n"
    arr = [["xi","ei","fi","Cumulative ei","Cumulative fi"]]
    @e.each_with_index { |e, i|
      x = @min + i
      unless e == 0
        arr << [x, e, @f[i], @cumulative_e[i], @cumulative_f[i]]
      end
    }
    str += arr.to_table + "\n" # use Erray
    str += "Mean : #{@mean}\n"
    str += "[Q1 - Median - Q3] : [#{@Q1} - #{@median} - #{@Q3}]\n"
    str += "Mode : #{@mode.join ','}\n"
    str += "Variance : #{@variance}\n"
    str + "Standard Deviation : #{@standard_deviation}\n"
  end
  alias :to_s :inspect
end