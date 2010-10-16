class Array
  # fork map
  def fmap
    return to_enum(__method__, processes) unless block_given?
    map { |e|
      from_child, to_parent = IO.pipe

      fork do
        from_child.close
        r = yield e
        to_parent.puts Marshal.dump(r) # [Marshal.dump(r)].pack("m")
        exit!
      end

      to_parent.close
      from_child
    }.map { |from_child|
      r = from_child.read
      from_child.close
      Marshal.load(r) # r.unpack("m").first
    }
  end
end

if __FILE__ == $0
  require "benchmark"
  N = 2_000_000
  Benchmark.bm(25) do |bm|
    bm.report('#map') {
      [1,2].map { (1..N).reduce(:+) }.reduce(:+)
    }
    bm.report('#fmap') {
      [1,2].fmap { (1..N).reduce(:+) }.reduce(:+)
    }
    puts
    bm.report('#map with huge data') {
      [1,2].map { "a"*N }
    }
    bm.report('#fmap with huge data') {
      [1,2].fmap { "a"*N }
    }
    puts
    bm.report('#map empty') {
      [1,2].map {  }
    }
    bm.report('#fmap empty') {
      [1,2].fmap {  }
    }
  end
end

__END__
                               user     system      total        real
#map                       1.200000   0.010000   1.210000 (  1.252787)
#fmap                      0.010000   0.000000   0.010000 (  0.694616)

#map with huge data        0.000000   0.000000   0.000000 (  0.005951)
#fmap with huge data       0.010000   0.020000   0.030000 (  0.045851)

#map empty                 0.000000   0.000000   0.000000 (  0.000011)
#fmap empty                0.000000   0.000000   0.000000 (  0.004500)
