#!/usr/bin/env ruby

# Auto Indent Ruby Code
# _indent.rb script, ... [-d DEBUG] [-s SHOW] [-f FORCE]
# Manage most ruby scripts
# Restriction: can only indent/outdent of 1 level per line (this is normal code design)
# Based on rbeautify

class Indent
  TAB = "  "

  IndentExp = [
    /^module\b/,
    /(=\s*|^)if\b/,
    /(=\s*|^)until\b/,
    /(=\s*|^)for\b/,
    /(=\s*|^)unless\b/,
    /(=\s*|^)while\b/,
    /(=\s*|^)begin\b/,
    /(=\s*|^|\s+)case\b/, # added for usage of "opt | case ..."
    /\bthen\b/,
    /^class\b/,
    /^rescue\b/,
    /^def\b/,
    /\b(?<!\.)do\b/, # don't match obj.do ...
    /^else\b/,
    /^elsif\b/,
    /^ensure\b/,
    /\bwhen\b/,
    /\{[^\}]*$/,
    /\[[^\]]*$/
  ]
  OutdentExp = [
    /^rescue\b/,
    /^ensure\b/,
    /^elsif\b/,
    /^end\b/,
    /^else\b/,
    /\bwhen\b/,
    /^[^\{]*\}/,
    /^[^\[]*\]/
  ]

  SINGLE_COMMENT_LINE = /^#/
  BLOCK_COMMENT_BEGIN = /^=begin/
  BLOCK_COMMENT_END = /^=end/
  CONTINUING_LINE = /[^\\]\\\s*$/ # ^\ \ \s*

  attr_accessor :path
  def initialize(path)
    @path = path.to_s
    @line = 0
    @source = IO.read(@path)
    @dest = ''
  end

  def add_line(line, tab)
    raise "problem of indentation(#{tab}) in #{@path} at line #{@line}\nDone:\n#{@dest}" if tab < 0
    line.strip!
    line = (TAB * tab) + line if line.length > 0
    line + "\n"
  end

  def indent
    comment_block = false
    multi_line_array = Array.new
    multi_line_str = ''
    tab = 0
    added, removed = 0, 0
    @errors = false

    @source.split("\n").each { |line|
      @line += 1
      # combine continuing lines
      if line.strip !~ SINGLE_COMMENT_LINE and line =~ CONTINUING_LINE
        multi_line_array << line
        multi_line_str += line.sub(/^(.*)\\\s*$/, '\1')
        next
      elsif multi_line_str.length > 0 # add final line
        multi_line_array << line
        multi_line_str += line.sub(/^(.*)\\\s*$/, '\1')
      end

      @tline = (multi_line_str.length > 0 ? multi_line_str : line).strip
      comment_block = true if(@tline =~ BLOCK_COMMENT_BEGIN)
      comment_line = (@tline =~ SINGLE_COMMENT_LINE)
      if comment_block
        @dest += line + "\n" # add the line unchanged
      else
        unless comment_line
          # throw out sequences that will only sow confusion

          remove_literal_string

          remove_literal_regexp

          @tline.gsub!( /#.*$/ , "") # throw end-line comments

          OutdentExp.each { |re|
            if(@tline =~ re)
              p ['o', @tline, re] if $DEBUG
              tab -= 1
              break
            end
          }
        end
        if multi_line_array.length > 0
          multi_line_array.each { |ml|
            @dest += add_line(ml,tab)
          }
          multi_line_array = []
          multi_line_str = ''
        else
          @dest += add_line(line, tab)
        end
        unless comment_line
          IndentExp.each { |re|
            if(@tline =~ re && !(@tline =~ /\s+end\s*$/))
              p ['i', @tline, re] if $DEBUG
              tab += 1
              break
            end
          }
        end
      end
      if @tline =~ BLOCK_COMMENT_END
        comment_block = false
      end
    }
    unless tab == 0
      puts "Indentation error: #{tab} tabs at EOF #{@path}"
      @errors = true
    end
    @dest.chomp!("\n") while @dest[-1,1] == "\n"
    @dest + "\n"
  end

  def indent!
    code = indent
    if code != @source and ($FORCE or !@errors)
      File.new(@path, 'w').write(code)
      puts @path
    end
    code != @source
  end

  def remove_literal_string
    @tline.gsub!( /\\'/, '') # \'
    @tline.gsub!( /\\"/, '') # \"

    @tline.gsub!( /#\{[^\{\}]*?(?<!\\)\}/, '') # #{..}
    @tline.gsub!( %r{".*?(?<!\\)"} , '""') # ".." => ""
    @tline.gsub!( %r{'.*?(?<!\\)'} , "''") # '..' => ''
  end

  def remove_literal_regexp
    # RegExp // or /.*[^\]/ Lazy(<>Greedy)
    @tline.gsub!( %r{\\/}, '') # \/

    @tline.gsub!( %r{/[^\/]*?(?<!\\)/(?! ?\d)} , '') # //
    @tline.gsub!( /%r\{.*?(?<!\\)\}/ , '') # %r{}
    @tline.gsub!( /%r([|`]).*?\1}/ , '') # %r``, %r||, ...
  end
end

if __FILE__ == $0
  $SHOW = false
  $FORCE = false
  OPTIONS = {
    '-d' => lambda { $DEBUG = true },
    '-s' => lambda { $SHOW = true },
    '-f' => lambda { $FORCE = true }
  }

  OPTIONS.each_pair { |option, proc|
    if ARGV.include? option
      ARGV.delete(option)
      proc.call
    end
  }

  files = []
  ARGV.each { |f|
    if File.file?(f) && File.extname(f) == ".rb"
      files << f
      # elsif File.directory? f
      # files += Dir[f+'/**/*.rb']
    end
  }

  if $SHOW
    files.each { |f|
      puts "#"*(f.length+4)
      puts "# #{f} #"
      puts "#"*(f.length+4)
      puts
      puts Indent.new(f).indent
    }
  else
    changed = files.inject(0) { |c, file|
      c + (Indent.new(file).indent! ? 1 : 0)
    }
    puts "#{changed} files indented (#{files.size-changed} already indented)"
  end
end
