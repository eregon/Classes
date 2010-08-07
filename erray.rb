# Class Erray (Eregon 2D Array)
# Eregon - 2008

class Erray
  include Enumerable
  def initialize(*args)
    @data = ((args.length == 1) && (args[0].is_a? Array)) ? args[0] : args
    @data ||= []
    case depth
    when 1
      @data.delete_if { |e| e.to_s == '' }
    when 2
      @data.delete_if { |line| line.join('') == '' }
    end
  end

  def depth(arr = @data)
    return 0 if arr.compact.length == 0
    depths = [1]
    arr.each { |sub|
      depths << 1+depth(sub) if sub.is_a? Array
    }
    depths.max
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
      out = "<ul>\n"
      @data.compact.each { |e|
        out += "\t<li>#{e}</li>\n" unless e.to_s == ''
      }
      out + "</ul>\n"
    when 2
      str = "<table>\n"
      max_rows = @data.max { |a, b| a.length <=> b.length }.length
      @data.each { |line|
        str += "\t<tr>"
        row = 0
        line.compact.each { |field|
          str += (field == '') ? "\t<td />" : "\t<td>#{field}</td>"
          row += 1
        }
        (max_rows-row).times { str += "\t<td />" }
        str += "\t</tr>\n"
      }
      str += "</table>\n"
      str
    end
  end
  def to_xml
    case depth
    when 0
      ''
    when 1
      ul = XML::Node.new('ul')
      @data.compact.each { |e|
        ul << XML::Node.new('li').text(e) unless e.to_s == ''
      }
      ul
    when 2
      table = XML::Node.new('table')
      max_rows = @data.max { |a, b| a.length <=> b.length }.length
      @data.each { |line|
        tr = table << XML::Node('tr')
        row = 0
        line.compact.each { |field|
          tr << XML::Node('td').set_text(field)
          row += 1
        }
        (max_rows-row).times { tr << XML::Node('td') }
      }
      table
    end
  end
  def inspect
    @data.each { |e| puts e }
  end
  alias :to_s :inspect

  #2D functions
  def row(n)
    @data.map { |e| e[n.to_i] }
  end
  alias :| :row
  def rows
    throw 'Only for 2D Array' unless depth == 2
    throw 'Missing fields' unless @data.map { |line| line.to_a.length }.uniq.length == 1
    Array.new(@data[0].length) { |i| @data.map { |e| e[i] } }
  end
  def to_table
    throw 'Only for 2D Array' unless depth == 2
    throw 'Missing fields' unless @data.map { |line| line.to_a.length }.uniq.length == 1
    lengths = (0...@data[0].length).map { |i|
      row(i).map { |e| e.to_s.length }
    }
    @data.map { |line|
      (0...@data[0].length).map { |i|
        line[i].to_s+ " "*(lengths[i].max - line[i].to_s.length)
      }.join(" ")
    }.join("\n")
  end
end

class Array
  def to_erray
    Erray.new(self).to_table
  end
end
