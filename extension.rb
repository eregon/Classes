=begin
July 2009
Code taken from the Ruby Extension Project
http://rubyforge.org/projects/extensions
http://extensions.rubyforge.org/
=end

module Enumerable
  #
  # Like <tt>#map</tt>/<tt>#collect</tt>, but it generates a Hash.  The block
  # is expected to return two values: the key and the value for the new hash.
  #   numbers  = (1..3)
  #   squares  = numbers.build_hash { |n| [n, n*n] }   # 1=>1, 2=>4, 3=>9
  #   sq_roots = numbers.build_hash { |n| [n*n, n] }   # 1=>1, 4=>2, 9=>3
  #
  def build_hash
    result = {}
    self.each do |e|
      key, value = yield e
      result[key] = value
    end
    result
  end

  #
  # Added by Eregon
  # Same as Enumerable#build_hash, with indexes
  #
  def build_hash_with_index
    result = {}
    self.each_with_index do |e, i|
      key, value = yield(e, i)
      result[key]= value
    end
    result
  end
end

class IO
  #
  # Writes the given data to the given path and closes the file.  This is
  # done in binary mode, complementing <tt>IO.read</tt> in standard Ruby.
  #
  # Returns the number of bytes written.
  #
  def IO.write(path, data)
    File.new(path, "wb").write(data)
  end
  #
  # Writes the given array of data to the given path and closes the file.
  # This is done in binary mode, complementing <tt>IO.readlines</tt> in
  # standard Ruby.
  #
  # Note that +readlines+ (the standard Ruby method) returns an array of lines
  # <em>with newlines intact</em>, whereas +writelines+ uses +puts+, and so
  # appends newlines if necessary.  In this small way, +readlines+ and
  # +writelines+ are not exact opposites.
  #
  # Returns +nil+.
  #
  def IO.writelines(path, data)
    File.new(path, "wb").puts(data)
  end
end