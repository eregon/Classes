require 'rspec'
require_relative '../module'

class Test
  def initialize
    @a = "a"
  end

  attr_cached :six do
    2*3
  end

  attr_cached :time do
    Time.now
  end

  attr_cached :context do
    @a * six
  end
end

describe "Module#attr_cached" do
  let(:test) { Test.new }

  it "caches an attribute" do
    test.six.should == 6
  end

  it "caches the result" do
    time = test.time
    test.time.should == time
    Test.new.should_not == time
  end

  it "can use instance context" do
    test.context.should == "aaaaaa"
  end
end
