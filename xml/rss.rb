=begin
Class RSS
=end

require_relative 'xml'

class RSS < XML::Document
  #0<rss>
  def initialize
    super
    @root = XML::Node.new('rss') * [
      :version, '2.0'
    ]
    @channel = @root << XML::Node.new('channel')
  end

  def save(name = 'feed.rss')
    name += '.rss' unless name[-4..-1] == '.rss'
    super(name)
  end

  #1<title>
  def title(title)
    @channel << XML::Node.new('title').set_text(title)
  end
  alias :title= :title
  #1<description>
  def description(desc)
    @channel << XML::Node.new('description').set_text(desc)
  end
  #1<link>
  def link(url)
    @channel << XML::Node.new('link').set_text(url)
  end

  #1<item>
  def item(link, title, desc = '')
    node = @channel << XML::Node.new('item')
    node << XML::Node.new('title').set_text(title)
    node << XML::Node.new('link').set_text(link)
    node << XML::Node.new('description').set_text(desc) unless desc == ''
    node
  end
end