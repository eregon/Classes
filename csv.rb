=begin
Class CSV (Comma Separated Values)
Parse a .csv from/to Array[line][field]
Never use a metacharacter as $delimiter or $quote(=>replace them before)

Eregon - 2008
=end

class CSV
  attr_reader :csv
  def initialize(str)
    @csv = str
  end

  def self.from_file(path)
    new(File.new(path, 'r').read)
  end

  def to_a(delimiter = ';', quote = '"', allow_space_before = false)
    lines = @csv.split(/\r\n|\r|\n/m)
    space = allow_space_before ? '[ ]?' : ''
    result = []
    n_fields_max = 0
    quotes_closed = true
    delim = Regexp.new(delimiter)
    for l in (0...lines.length)
      line = lines[l]
      data = line.strip
      if (data.scan(/delimiter/).length % 2) == 1
        raise 'Unmatched quote at the last line.' if lines[l+1].nil?
        lines[l+1] = line + lines[l+1]
        data = ''
        quotes_closed = false
      elsif !quotes_closed
        quotes_closed = true
      end
      unless(data == '')
        if (data =~ Regexp.new(quote)).nil?
          result[l] = data.split(delim)
        else
          throw "CSV Regex doesn't work"
          #result[l] = data.match(Regexp.new('(?<=^|'+delimiter+')'+space+quote+'?((?(?<='+quote+')(?:(?:'+quote+quote+'|[^'+quote+'])*(?='+quote+delimiter+'|'+quote+'$))|(?:[^'+delimiter+quote+']*(?='+delimiter+'|$))))', Regexp::EXTENDED+Regexp::MULTILINE))
        end
        n_fields_max = [ result[-1..1].length, n_fields_max].max
      end
    end
    result.compact!
    result.each { |e|
      (n_fields_max - e.length).times { e << '' }
    }
    result
  end
end
