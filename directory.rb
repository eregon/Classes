class DirList
  def initialize(dir, files)
    @dir = dir.to_s
    @files = files.to_a
  end
  def inspect
    str = 'Directory Listing ' + @dir + "\n"
    @files.each { |f|
      str += f + "\n"
    }
    str
  end
  alias :to_s :inspect
end
class FileList
  include Enumerable
  def initialize(files)
    @files = files.to_a
  end
  def inspect
    str = ''
    @files.each { |f|
      str += f + "\n"
    }
    str
  end
  alias :to_s :inspect
  def each
    @files.each { |f| yield f }
  end
end

class Directory
  attr_accessor :dir
  def initialize(path)
    @dir = path.to_s.gsub(/\\/, '/')
    unless @dir[-1..1] == '/'
      @dir += '/'
    end
  end
  def ls(flag = :all)
    #flag = :all :file :dir
    if flag == :file
      Dir[@dir+'*.*']
    elsif flag == :dir
      Dir[@dir+'*'].select { |f| File.directory?(f) }
    elsif flag == :all
      Dir[@dir+'*']
    end
  end
  def browse(flag = :file)
    #flag = :all :file :dir
    if flag == :file
      Dir[@dir+'**/*.*']
    elsif flag == :all
      Dir[@dir+'**/*']
    elsif flag == :dir
      Dir[@dir+'**/']
    end
  end
  def glob(s)
    Dir[s.to_s]
  end
end
