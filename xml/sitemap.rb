=begin
Class SiteMap
Representation of the architecture of a web site in XML
=end

require_relative 'xml'
require 'date'

class SiteMap < XML::Document
  #<urlset>
  def initialize
    super
    @root = XML::Node.new('urlset') * [
      :xmlns, 'http://www.sitemaps.org/schemas/sitemap/0.9',
      :"xmlns:xsi", 'http://www.w3.org/2001/XMLSchema-instance',
      :"xsi:schemaLocation", 'http://www.sitemaps.org/schemas/sitemap/0.9'
    ]
  end

  def save
    super('SiteMap.xml')
  end

  #<url>
  # >loc : url
  # >lastmod : AAAA-MM-DD
  # >changefreq : always hourly daily weekly monthly yearly never
  # >priority : 0.0-1.0
  def url(path, priority = 0.5, freq = 'weekly')
    url_tag = @root << XML::Node.new('url')
    url_tag << XML::Node.new('loc').set_text(path)
    url_tag << XML::Node.new('lastmod').set_text(Time.now.strftime("%Y-%m-%d"))
    url_tag << XML::Node.new('changefreq').set_text(freq)
    url_tag << XML::Node.new('priority').set_text(priority)
    url_tag
  end
end