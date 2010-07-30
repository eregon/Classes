=begin
Class Cooliris
=end

require_relative 'xml'

class Cooliris < XML::Document
  #<rss>
  def initialize
    super
    @root = XML::Node.new('rss') * [
      :version, '2.0',
      :"xmlns:media", "http://search.yahoo.com/mrss/",
      :"xmlns:atom", "http://www.w3.org/2005/Atom"
    ]
    @channel = @root << XML::Node.new('channel')
  end

  def save
    super('cooliris.rss')
  end

  #<item>
  def item(img, thumb)
    node = @channel << XML::Node.new('item')
    #node << XML::Node.new('title').set_text(img)
    #node << XML::Node.new('link').set_text(img)
    node << XML::Node.new('media:thumbnail') * [:url, thumb]
    node << XML::Node.new('media:content') * [:url, img]
    node
  end
end