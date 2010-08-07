# This file must be copied in the lib dir of old installation and then used as
# ruby18 -ruby19 script.rb
# so this file name is uby19.rb
#
# It can also be required as "require 'path/to/uby19'"
#
# On Mac, it must be in (for stock Ruby)
# /System/Library/Frameworks/Ruby.framework/Versions/Current/usr/lib/ruby/1.8
#
# This is very basic, you should have a look to the `backports` gem instead
if RUBY_VERSION < "1.9"
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end

  class Symbol
    def to_proc
      @to_proc ||= Proc.new { |*args| args.shift.send(self, *args) }
    end
  end
end
