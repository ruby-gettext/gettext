# encoding: utf-8

=begin
  parser/erb.rb - parser for ERB

  Copyright (C) 2005-2009  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.
=end

require 'erb'
require 'gettext/tools/parser/ruby'

module GetText
  class ErbParser
    @config = {
      :extnames => ['.rhtml', '.erb']
    }

    class << self
      # Sets some preferences to parse ERB files.
      # * config: a Hash of the config. It can takes some values below:
      #   * :extnames: An Array of target files extension. Default is [".rhtml"].
      def init(config)
        config.each{|k, v|
          @config[k] = v
        }
      end

      def target?(file) # :nodoc:
        @config[:extnames].each do |v|
          return true if File.extname(file) == v
        end
        false
      end

      def parse(path)
        parser = new(path)
        parser.parse
      end
    end

    MAGIC_COMMENT = /\A#coding:.*\n/

    def initialize(path)
      @path = path
    end

    def parse # :nodoc:
      content = IO.read(@path)
      src = ERB.new(content).src

      # Force the src encoding back to the encoding in magic comment
      # or original content.
      encoding = detect_encoding(src) || content.encoding
      src.force_encoding(encoding)

      # Remove magic comment prepended by erb in Ruby 1.9.
      src = src.gsub(MAGIC_COMMENT, "")

      erb = src.split(/$/)
      RubyParser.new(@path).parse_lines(erb)
    end

    def detect_encoding(erb_source)
      if /\A#coding:(.*)\n/ =~ erb_source
        $1
      else
        nil
      end
    end
  end
end

if __FILE__ == $0
  # ex) ruby glade.rhtml foo.rhtml  bar.rhtml
  ARGV.each do |file|
    p GetText::ErbParser.parse(file)
  end
end
