=begin
Class SubTitle
Eregon - 2008
Manage subtitles .sub format
=end

module SubTitle
  class SubTime
    attr_reader :time
    def initialize *args
      h, m, s, ms = [0]*4
      case args.length
      when 4
        h, m, s, ms = args.map(&:to_i)
      when 2
        s, ms = args.map(&:to_i)
      when 1
        raise unless Time === args[0]
        s = args[0].to_i
        ms = args[0].usec/1000
      end

      @time = Time.at((h*60 + m)*60 + s, ms*1000).getutc
    end

    def msec
      @time.usec/1000
    end

    def == t
      SubTime === t and @time == t.time
    end

    def + t
      SubTime.new(@time+t)
    end

    def * c
      s, ms = self.to_s_ms
      SubTime.new(s * c, ms * c)
    end

    def to_s_ms
      [@time.to_i, self.msec]
    end

    def to_hms_ms
      if @time.to_i >= 0
        [@time.hour, @time.min, @time.sec, msec]
      else
        [0]*4
      end
    end
  end

  class St
    # CONVERT_TO_DURATION = -> h, m, s, ms { (h.to_i*60 + m.to_i)*60 + s.to_i + ms.to_f/1000 }
    # CONVERT_TO_UNITS = -> s {
    #   ms = (s-s.to_i)*1000
    #   s = s.to_i
    #   h = s / 3600
    #   m = (s % 3600) / 60
    #   s %= 60
    #   [h, m, s, ms]
    # }
    IVARS = -> object {
      object.instance_variables.each_with_object({}) { |ivar, h|
        h[ivar] = object.instance_variable_get(ivar)
      }
    }

    attr_accessor :start, :stop, :text
    def initialize start, stop, text
      @start, @stop, @text = start, stop, text.to_s
    end
    def + t
      @start += t
      @stop += t
      self
    end
    def * c
      @start *= c
      @stop *= c
      self
    end

    def == other
      self.class == other.class && IVARS[self] == IVARS[other]
    end
  end

  class Srt < St
    TIME_REGEX = /(\d{2}):(\d{2}):(\d{2}),(\d{3})/
    TIME_FORMAT = "%02d:%02d:%02d,%03d"

    NUMBER_REGEXP = /\A\d+\Z/

    HEADER_REGEXP = /\A#{TIME_REGEX} --> #{TIME_REGEX}\Z/
    HEADER_FORMAT = "#{TIME_FORMAT} --> #{TIME_FORMAT}"

    attr_reader :i
    def initialize i, start, stop, text
      super(start, stop, text)
      @i = i
    end

    def inspect
      str = "#{@i}\n"
      str << (HEADER_FORMAT % (@start.to_hms_ms+@stop.to_hms_ms)) << "\n"
      str << text.gsub(' | ', "\n") + "\n"
    end
    alias :to_s :inspect

    def Srt.load(str)
      str.lines.slice_before(NUMBER_REGEXP).map.with_index(1) { |st, i|
        if st.size >= 2 and st[1].strip =~ HEADER_REGEXP
          from, to = SubTime.new(*$~[1..4]), SubTime.new(*$~[5..8])
          text = st[2..-1].join.strip
          Srt.new(i, from, to, text)
        else
          raise "Incorrect subtitle: #{st.join}"
        end
      }
    end

    def Srt.dump(sts)
      sts.join("\n")
    end
  end

  class Sub < St
  #   def inspect
  #     str = "{#{@start.to_i}}{#{@stop.to_i}}#{@text.to_s}"
  #   end
  #   alias :to_s :inspect
  #
  #   def Sub.load(str)
  #     fps = yield
  #     str.lines.with_object([]) { |st, sts|
  #       st.strip!
  #       unless st.empty?
  #         data = st.match(/^\{([0-9]+)\}\{([0-9]+)\}(.+)$/)
  #         raise "Incorrect subtitle : #{str}" if data.nil?
  #         sts << Sub.new(data[1].to_i, data[2].to_i, data[3].to_s)
  #       end
  #     }
  #   end
  #   def Sub.dump(sts)
  #     sts.join("\n")
  #   end
  end

  class SubTitle
    attr_writer :fps
    attr_reader :type, :sts
    def initialize(contents, type, fps = nil)
      @contents, @type = contents, type
      @fps = fps.to_i if fps
      @sts = @type.load(@contents)
    end

    def self.load(path, fps = nil)
      contents = IO.read(path)
      type = case File.extname(path)
      when ".srt"
        Srt
      when ".sub"
        Sub
      end
      SubTitle.new(contents, type, fps)
    end

    def inspect
      @type.dump(@sts)
    end
    alias :to_s :inspect

    def convert_by_ref vid, sub
      ratio = (vid.last - vid.first).to_f / (sub.last - sub.first)
      offset = vid.first-sub.first*ratio
      @sts.map! { |st| st*ratio+offset }
      self
    end

    # def to_sub
    #   unless @type == Sub
    #     @sts.map! { |st|
    #       Sub.new(st.start, st.stop, st.text)
    #     }
    #   end
    #   @type = Sub
    #   self
    # end
    #
    # def to_srt
    #   unless @type == Srt
    #     @sts.map! { |st|
    #       Srt.new(st.start, st.stop, st.text)
    #     }
    #   end
    #   @type = Srt
    #   self
    # end

    def save(name)
      if File.exist?(name)
        ext = File.extname(name)
        name = @path.sub(/#{ext}$/, ".sync#{ext}")
      end
      File.open(name, 'w') { |f|
        f.write(self.to_s)
      }
    end
  end

  def self.new(*a, &b)
    SubTitle.new(*a, &b)
  end
end

if __FILE__ == $0
  require "minitest/autorun"
  include SubTitle

  SRT = <<SRT
1
00:00:01,217 --> 00:00:05,210
If a photon is directed through a plane
with two slits in it and either is observed...

2
00:00:05,388 --> 00:00:07,913
...it will not go through both.
If unobserved, it will.

3
00:00:08,091 --> 00:00:11,322
If it's observed after it left the plane,
before it hits its target...
SRT

SRTS = [
  Srt.new(1, SubTime.new(1, 217), SubTime.new(5, 210), "If a photon is directed through a plane\nwith two slits in it and either is observed..."),
  Srt.new(2, SubTime.new(5, 388), SubTime.new(7, 913), "...it will not go through both.\nIf unobserved, it will."),
  Srt.new(3, SubTime.new(8, 91), SubTime.new(11, 322), "If it's observed after it left the plane,\nbefore it hits its target...")
]

  class TestSubtitle < MiniTest::Unit::TestCase
    def test_time
      t = SubTime.new(rand(10000), 253)
      assert_equal t, SubTime.new(*t.to_hms_ms)
    end

    def test_srt
      assert_equal SRTS, Srt.load(SRT)
      assert_equal SRT, Srt.dump(Srt.load(SRT))
    end

    def test_neutral
      b = 1+rand(3)
      i = 5+rand(5)
      assert_equal SRTS, SubTitle.new(SRT, Srt).convert_by_ref( b..i , b..i ).sts
    end

    def test_add_sec
      assert_equal SRTS, SubTitle.new(SRT, Srt).sts
      srts_double = SRTS.map { |srt|
        Srt.new(srt.i, srt.start*2, srt.stop*2, srt.text)
      }
      assert_equal srts_double, SubTitle.new(SRT, Srt).convert_by_ref( 0..2 , 0..1 ).sts
    end

    def test_complete
      assert_equal SRTS, SubTitle.new(SRT, Srt).sts
      srts_double = SRTS.map { |srt|
        Srt.new(srt.i, srt.start*2+1, srt.stop*2+1, srt.text)
      }
      assert_equal srts_double, SubTitle.new(SRT, Srt).convert_by_ref( 1..3 , 0..1 ).sts
    end
  end
end
