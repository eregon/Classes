require 'thread'

class Array
  def pmap threads = size
    return to_enum(__method__, threads) unless block_given?
    step = (size.to_f/threads).ceil
    results = Array.new(size)
    threads = (0...size).step(step).map { |start|
      Thread.new(start, [start+step,size].min) do |start, stop|
        (start...stop).each { |i|
          results[i] = yield self[i]
        }
      end
    }
    threads.each(&:join)
    results
  end

  def pqmap threads = size
    return to_enum(__method__, threads) unless block_given?
    results = Array.new(size)
    queue = Queue.new
    each_with_index { |e, i| queue << [e, i] }
    threads = threads.times.map { |t|
      queue << nil # stopper
      Thread.new(t+1) { |t|
        while data = queue.pop
          e, i = data
          results[i] = yield e
        end
      }
    }
    threads.each(&:join)
    results
  end
end

if __FILE__ == $0
  require 'open-uri'
  require 'benchmark'
  N = 6
  THREADS = 3
  urls = %w[
    google.be microsoft.com apple.com
    github.com ruby-lang.org rvm.beginrescueend.com
    eregon.me microsoft.com yahoo.com
    www.slideshare.net
    twitter.com rubygems.org
  ]
  p urls.size
  urls = (urls*(N/urls.size+1)).map { |site| "http://#{site}" }[0...N]

  Benchmark.bm do |x|
    x.report("pqmap") {
      p urls.pqmap(THREADS) { |url| open(url, &:read).size }
    }
    x.report("pmap") {
      p urls.pmap(THREADS) { |url| open(url, &:read).size }
    }
    x.report("map") {
      p urls.map { |url| open(url, &:read).size }
    }
  end
end

__END__
(N,THREADS):
pmap, map
pqmap, pmap, map

(2,2):
2.09 3.66
1.22 2.75
1.38 3.58
1.56 2.40
2.22 2.84
1.75 1.95

(6,3):
3.75 7.25
3.43 6.68
3.61 7.61
3.41 7.60
3.55 3.39 6.75
3.88 3.58 7.51
3.51 3.46 6.88

(6,6):
2.67 7.09
2.91 7.32
2.87 7.99
2.78 3.41 7.84
2.81 2.74 6.94
2.63 2.85 7.62
3.14 2.71 8.46
2.76 2.62 7.46
2.63 2.60 7.44
2.67 2.60 6.53

(25,25):
with 6 differents urls:
4.46 3.84 28.0
with 12 differents urls:
3.69 3.25 55.7

(25,10):
with 12 differents urls:
4.01 5.33 28.9
5.12 5.48 27.6
3.79 4.34 27.6
4.50 4.23 29.3

(100,10):
with 12 differents urls:
13.4 15.0 125
13.4 14.2 183

