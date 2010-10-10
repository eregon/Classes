# Class Erray (Eregon 2D Array)
# Eregon - 2008

class Erray
  include Enumerable
  def initialize(*args)
    @data = (args.size == 1 and Array === args[0]) ? args[0] : args
    @data ||= []
    case depth
    when 1
      @data.delete_if { |e| e.to_s == '' }
    when 2
      @data.delete_if { |line| line.join == '' }
    end
  end

  def depth(ary = @data)
    return 0 if ary.compact.length == 0
    ary.each_with_object([1]) { |row, depths|
      depths << 1 + depth(row) if Array === row
    }.max
  end

  def [](i)
    @data[i]
  end
  def []=(i, v)
    @data[i] = v
  end
  def each
    @data.each { |e| yield e }
  end

  def to_a
    @data
  end

  def to_html
    case depth
    when 0
      ''
    when 1
      @data.compact.each_with_object("<ul>\n") { |e, s|
        s << "\t<li>#{e}</li>\n" unless e.to_s == ''
      } << "</ul>\n"
    when 2
      max_rows = @data.max { |a, b| a.length <=> b.length }.length
      @data.inject("<table>\n") { |str, line|
        str << "\t<tr>"
        line.compact.each_with_index { |field, row|
          str << (field == '') ? "\t<td />" : "\t<td>#{field}</td>"
        }
        (max_rows-line.compact.size).times { str += "\t<td />" }
        str << "\t</tr>\n"
      } << "</table>\n"
    end
  end
  def to_xml
    case depth
    when 0
      ''
    when 1
      @data.compact.each_with_object(XML::Node.new('ul')) { |e, ul|
        ul << XML::Node.new('li').text(e) unless e.to_s == ''
      }
    when 2
      table = XML::Node.new('table')
      max_rows = @data.max_by(&:size).size
      @data.each { |line|
        tr = table << XML::Node('tr')
        line.compact.each_with_index { |field, row|
          tr << XML::Node('td').set_text(field)
        }
        (max_rows-line.compact.size).times { tr << XML::Node('td') }
      }
      table
    end
  end
  def inspect
    @data.each { |e| puts e }
  end
  alias :to_s :inspect

  #2D functions
  def to_table
    raise 'Only for 2D Array' unless depth == 2
    throw 'Missing fields' unless @data.map(&:size).uniq.size == 1
    max_lengths = @data.transpose.map { |col| col.map { |e| e.to_s.length }.max }
    @data.map { |row|
      row.map.with_index { |e, i|
        e.to_s.ljust(max_lengths[i])
      } * "\t"
    } * "\n"
  end
end

class Array
  def to_table
    Erray.new(self).to_table
  end
end
