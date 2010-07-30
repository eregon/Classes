=begin
Class XML
eXtensible Markup Language
Eregon - 2008

exemple:
doc = XML::Document.new('1.0', 'UTF-8', true)
doc.header = '<!DOCTYPE...'
doc.root = XML::Node.new('root_name', [:xmlns, 'url', :"xmlns:xlink", 'url'])
doc.root << tag = XML::Node.new('tag') * [:attr1, :val1]
tag['name'] = 'value'
tag << subtag = XML::Node.new('subtag').set_text('exemple text')
puts doc

=end

module XML
  class Attribute
    attr_reader :n, :v
    def initialize(name, value)
      @n, @v = name.to_s, value.to_s
    end
    def inspect
      @v.gsub!('"', '\"')
      if @v == '' || @n == ''
        ''
      elsif @n == 'style'
        @v.chomp!(';') while @v[-1,1] == ';'
        "#{@n}=\"#{@v}\""
      else
        "#{@n}=\"#{@v}\""
      end
    end
    alias :to_s :inspect
  end

  class Attributes
    # String node : node name(used for sorting)
    attr_writer :node
    @@attr_order = {
      'default' => ['id', 'class', '*', 'style']
    }
    def initialize
      @attributes = []
      @node = 'default'
    end

    def self.add_sort(name, arr)
      @@attr_order[name.to_s] = arr.to_a
    end

    def length
      @attributes.length
    end
    def select(name)
      s = @attributes.select { |attribute| attribute.n == name.to_s }
      (s.length == 0) ? '' : s[0].v
    end

    def <<(atr)
      @attributes << atr if atr.is_a? XML::Attribute
    end
    def sort!
      @node = 'default' unless @@attr_order.has_key? @node
      original = @attributes.dup
      esort = @@attr_order[@node]
      @attributes.sort! { |a, b|
        ai, bi = esort.index(a.n), esort.index(b.n)
        ai = esort.index('*') if ai.nil?
        bi = esort.index('*') if bi.nil?
        if ai == bi
          original.index(a) <=> original.index(b)
        else
          ai <=> bi
        end
      }
    end
    def inspect
      sort!
      (@attributes.length == 0) ? '' : @attributes.join(' ')
    end
    alias :to_s :inspect
  end

  class Node
=begin
String name
XML::Node parent
[XML::Node] children
[XML::Attribute] attributes
String text : text in the tag
String CDATA : CDATA section
=end
    attr_reader :attributes, :name, :children
    attr_accessor :parent
    def initialize(name, attributes = [])
      @name = name.to_s
      @attributes = Attributes.new
      for i in (0...attributes.length/2)
        set_attribute(attributes[2*i], attributes[2*i+1])
      end
      @children = []
    end

    def remove
      @parent.remove_child(self)
    end

    def add_child(child)
      if child.is_a? Array
        child.each { |c| add_child(c) }
      else
        child = XML::Return.new if child == "\n"
        @children << child
        child.parent = self
      end
      child
    end
    alias :<< :add_child

    def remove_child(child)
      @children -= [child]
    end
    alias :>> :remove_child

    def get_children(name)
      @children.map { |child|
        child if child.name == name
      }.flatten.compact
    end
    def get_child(name)
      get_children(name)[0]
    end
    def descendants
      des = @children
      @children.each { |child|
        des += child.descendants unless child.children.length == 0
      }
      des
    end

    def [](name)
      @attributes.select(name)
    end
    def set_attribute(name, value)
      unless(name.to_s.empty? || value.to_s.empty?)
        if (att = @attributes.select(name)).length == 1
          att.v = value.to_s
        else
          @attributes << XML::Attribute.new(name, value)
        end
      end
      self
    end
    alias :[]= :set_attribute

    def set_attributes(attributes)
      for i in (0...attributes.length/2)
        set_attribute(attributes[2*i], attributes[2*i+1])
      end
      self
    end
    alias :* :set_attributes

    def id(id)
      set_attribute(:id, id)
    end
    alias :- :id

    def set_text(str)
      return set_CDATA(str) if str.to_s.include? '&'
      add_child(XML::Text.new(str)) unless str.to_s.empty?
      self
    end
    def set_CDATA(str)
      add_child(XML::CDATA.new(str)) unless str.to_s.empty?
      self
    end

    def xpath(query)
      XML::XPath.new(self).xpath(query)
    end

    def inspect
      str = "<#{@name}"
      str += ' ' unless @attributes.length == 0
      @attributes.node = @name.to_s
      str += @attributes.to_s
      b_text = defined? @text
      b_cdata = defined? @CDATA
      if(b_text || b_cdata)
        if b_cdata
          str += "><![CDATA[#{@CDATA}]]></#{@name}>"
        elsif b_text
          str += ">#{@text}</#{@name}>"
        end
      elsif @children.length > 0
        str += ">"
      else
        str += "/>"
      end
      str += "\n" unless(@children.length == 1 && ((@children[0].is_a? XML::Text) || (@children[0].is_a? XML::CDATA)))
      str
    end
    alias :to_s :inspect
  end
  def self.Node(name, attributes = [])
    Node.new(name, attributes)
  end

  class Text
    attr_reader :str, :children, :attributes, :name
    attr_accessor :parent
    def initialize(str)
      @str = str.to_s
      @children, @attributes, @name = [], Attributes.new, ''
    end
    def inspect
      @str
    end
    alias :to_s :inspect
  end
  def self.Text(str)
    Text.new(str)
  end

  class CDATA
    attr_reader :str, :children, :attributes, :name
    attr_accessor :parent
    def initialize(str)
      @str = str.to_s
      @children, @attributes, @name = [], Attributes.new, ''
    end
    def inspect
      "<![CDATA[#{@str}]]>"
    end
    alias :to_s :inspect
  end

  class Return
    attr_reader :children, :attributes, :name
    attr_accessor :parent
    def initialize
      @children, @attributes, @name = [], Attributes.new, ''
    end
    def inspect
      "\n"
    end
    alias :to_s :inspect
  end
  RETURN = Return.new

  class Comment
    attr_reader :children, :attributes, :name
    attr_accessor :parent
    def initialize(str)
      @str = "<!-- #{str.gsub('--','')} -->"
      @children, @attributes, @name = [], [], ''
    end
    def inspect
      @str + "\n"
    end
    alias :to_s :inspect
  end
  def self.Comment(str)
    Comment.new(str)
  end

  class Document
=begin
String version, encoding
Boolean standalone
String header : string printed bewteen xml declaration and the root
XML::Node root
String tab
=end
    attr_reader :version, :encoding, :standalone
    attr_writer :header
    attr_accessor :root, :tab
    alias :<< :root=

    def initialize(version = '1.0', encoding = 'UTF-8', standalone = false)
      @version, @encoding, @standalone = version, encoding, standalone
      @tab = "\t"
      @precision = -1
    end

    def indent(str, tabs)
      indentation = (tabs >= 0) ? @tab.to_s * tabs : ''
      puts "Bad indentation: #{tabs}" if tabs < 0
      if str.include? "\n"
        str.rstrip.split("\n").map { |line| indentation << line.rstrip }.join("\n")+"\n"
      else
        indentation << str
      end
    end

    def append_child(child, tabs, parent)
      if (child.is_a? XML::Node) || (child.is_a? XML::Comment)
        str = indent(child.to_s, tabs)
      elsif (child.is_a? XML::Text) || (child.is_a? XML::CDATA)
        str = child.to_s
        if parent.children.length > 1
          str = indent(str, tabs).rstrip+"\n"
        elsif str.include? "\n"
          str = indent(str, tabs-1).strip
        end
      elsif (child.is_a? XML::Return)
        str = child.to_s
      end
      #recursive
      if child.children.length > 0
        child.children.each { |sub_child|
          str << append_child(sub_child, tabs+1, child)
        }
        str << (child.children.length == 1 && ((child.children[0].is_a? XML::Text) || (child.children[0].is_a? XML::CDATA)) ? "</#{child.name}>\n" : indent("</#{child.name}>\n", tabs))
      end
      str
    end

    def inspect
      str = %Q{<?xml version="#{@version}" encoding="#{@encoding}" standalone="#{@standalone ? 'yes' : 'no'}"?>\n}
      str << "#{@header.to_s.rstrip}\n" if defined? @header
      str << append_child(root, 0, root)
    end
    alias :to_s :inspect

    def xpath(query)
      XML::XPath.new(self).xpath(query)
    end

    def save(path)
      File.open(path.to_s, 'w') { |f| f.write(inspect) }
    end
  end

  class XPath
    attr_accessor :node
    def initialize(arg)
      @node = arg.root if arg.is_a? XML::Document
      @node = arg if arg.is_a? XML::Node
    end

    def xpath(expr)
      expr = expr.to_s
      nodes = [@node]
      if expr =~ %r{^/([a-zA-Z0-9]+)} && $1 == @node.name
        expr = $'
      end
      until expr.empty?
        expr.gsub!(/^\s+|\s+$/, '')
        case expr
        when %r{^\.\.} # ..
          expr = $'
          nodes.map! { |node| node.parent }
        when %r{^/?([a-zA-Z0-9]+)} #child
          expr = $'
          nodes = nodes.map { |node| node.get_children($1) }.flatten
        when %r{^\[@([a-zA-Z0-9]+)=(?:'|")([a-zA-Z0-9]*)(?:"|')\]} # [attr='value']
          expr = $'
          nodes = nodes.select { |node| node[$1] == $2 }
        when %r{^//([a-zA-Z0-9]+)}
          expr = $'
          nodes = nodes.map { |node|
            node.descendants.uniq.select { |n|
              n.name == $1
            }
          }.flatten
        else
          puts "Error: #{expr}"
          break
        end
      end
      nodes.uniq
    end
  end

  def self.show(o)
    case o
    when XML::Node
      XML::Document.new.append_child(o, 0, o)
    end
  end
end