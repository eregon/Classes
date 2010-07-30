require 'benchmark'

module Benchmark
  def find(range, p = 1, &block)
    min = realtime { block.call(range.begin) }
    raise "min too high: #{min}" if min > 1.0
    max = realtime { block.call(range.end) }
    raise "max too low:  #{max}" if max < 1.0
    mean = (range.begin+range.end)/2
    mid = realtime { block.call(mean) }
    puts "in #{range}:\tmin:#{min},\tmid:#{mid},\tmax:#{max}"

    if (mid-1.0).abs <= p
      puts "#{mean} times in #{mid}"
      mean
    elsif mid < 1.0
      find(mean..range.end, p, &block)
    elsif mid > 1.0
      find(range.begin..mean, p, &block)
    end
  end
=begin
  def upto_n_by_s(type = :linear, n = 1, p = 0.1, &block)
    # type: :linear, :log, :exp
    #n = n.to_i
    #start_time = realtime { block.call(n) }
    #frac = 1.0/start_time

    get_slowly = 1#0.8

    n = n.to_i
    time = realtime { block.call(n) }
    puts "Tried with #{n}: #{time}"

    try = case type
    when :linear
      n / time * get_slowly
      #when :exp
      #0#(start+start**0.5).to_i#TODO
    when :log
      n ** (1.0/time) * get_slowly
    else
      raise "Wrong type: must be one of :linear, :exp, :log"
    end
    try = try.to_i

    #time = realtime { block.call(try) }
    #puts "Started with #{n}: #{start_time}"
    #puts "Tried   with #{try}: #{time}"

    if (time - 1).abs < p
      puts "#{try} times in #{time}"
      puts "In 1 s:"
      puts "#{(try/time).to_i}"
      time
    elsif time < 1
      upto_n_by_s(type, try, p, &block)
    elsif time > 1
      upto_n_by_s(type, try, p, &block)
    end
  end
=end
end