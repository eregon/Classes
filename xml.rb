Dir[File.dirname(__FILE__)+'/xml/*.rb'].each { |f|
  require f
}