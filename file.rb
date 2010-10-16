class EFile
  def initialize path
    @path = path
  end

  def read
    File.open(@path) { |f| f.read }
  end
  def binread
    File.binread(@path)
  end

  def write contents
    File.open(@path, 'w') { |f| f.write contents }
  end
end

def File path
  EFile.new path
end

=begin
Wanted API:
File('dir/file.ext').read # auto-open, auto-close
File('dir/file.ext').write('contents')
=end
