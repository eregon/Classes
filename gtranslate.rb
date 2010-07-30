=begin
Google::Translate
Ruby Google Translate Library

Benoit Daloze
June 2009
Based on the project of caius
=end

require 'yaml'
require 'uri'
require 'net/http' # 1.9 error with zlib
require 'json' # 1.9 error with recurse_proc

module Google
  #
  # Call a method of the following type:
  #   {language from}_to_{language to}
  #
  # Or to have the language from automagically detected:
  #   to_{language to}
  #
  # Eg:
  #   english_to_french
  #   to_french
  #
  module Translate
    # Loads the lanuages in from a data file
    LANGS = YAML.load_file(File.dirname(__FILE__) + "/data/gtranslate.languages.yml")

    BASE_URI = URI.parse("http://ajax.googleapis.com/ajax/services/language/translate")
    DEFAULT_OPTIONS = { "v" => "1.0", "hl" => "en" }

    HTML_ENTITIES = {
      '&#39;' => "'"
    }

    def self.method_missing(method, *args)
      if find = method.to_s.match(/([A-Za-z-]+?)?_?to_([A-Za-z-]+)/)
        langs = find.captures

        langs.each_with_index do |lang, i|
          raise "InvalidLanguage: #{lang}" unless (lang.nil? && i == 0) || LANGS.key?(lang.to_sym)
        end

        raise "NoPhrasePassed: Pass a phrase to translate" if args[0].nil? || args[0].empty?
        from = (langs[0].nil?) ? "" : LANGS[langs[0].to_sym]

        get_translation :from => from, :to => LANGS[langs.last.to_sym], :phrase => args[0]
      else
        super
      end
    end

    def self.get_translation( opts = {} )
      response = JSON.parse Net::HTTP.post_form( BASE_URI, {"langpair" => "#{opts[:from]}|#{opts[:to]}", "q" => opts[:phrase]}.merge(DEFAULT_OPTIONS) ).body
      # {"responseData": {"translatedText":"Ici"}, "responseDetails": null, "responseStatus": 200}
      # ["responseData"]["translatedText"]
      if response["responseStatus"] == 200
        HTML_ENTITIES.each_pair.with_object(response["responseData"]["translatedText"]) { |(e,c), s|
          s.gsub!(e, c)
        }
      else
        raise "BadResponse: #{response}"
      end
    end

    # Extends String to add to_* and *_to_*
    module StringMixin
      def method_missing(name, *args)
        if name.to_s =~ /^to_([A-Za-z-]+)$/ && Google::Translate::LANGS.value?($1)
          Google::Translate.send(name, self)
        elsif name.to_s =~ /^([A-Za-z-]+)_to_([A-Za-z-]+)$/ && Google::Translate::LANGS.value?($1) && Google::Translate::LANGS.value?($2)
          Google::Translate.send(name, self)
        else
          super
        end
      end
    end
  end
end

String.send(:include, Google::Translate::StringMixin)

if __FILE__ == $0
  require "test/unit"

  class TestGtranslate < Test::Unit::TestCase
    def test_simple
      assert_equal("un chien", "a dog".to_fr)
      assert_equal("un chien", "a dog".en_to_fr)
      assert_equal("l'or", "the gold".to_fr)
      assert_equal("tree", "l'arbre".to_en)
    end
  end
end