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
