# -*- coding: utf-8 -*-

=begin
  parser/erb.rb - parser for ERB

  Copyright (C) 2005-2009  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.
=end

require 'erubi'
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

      # Parses eRuby script located at `path`.
      #
      # This is a short cut method. It equals to `new(path,
      # options).parse`.
      #
      # @return [Array<POEntry>] Extracted messages
      # @see #initialize and #parse
      def parse(path, options={})
        parser = new(path, options)
        parser.parse
      end
    end

    # @param path [String] eRuby script path to be parsed
    # @param options [Hash]
    def initialize(path, options={})
      @path = path
      @options = options
    end

    # Extracts messages from @path.
    #
    # @return [Array<POEntry>] Extracted messages
    def parse
      content  = IO.read(@path)
      encoding = detect_encoding(content)

      if encoding != 'UTF-8'
        content.force_encoding(encoding).encode('UTF-8')
      end

      erb = Erubi::Engine.new(content)
      src = erb.src

      RubyParser.new(@path, @options).parse_source(src)
    end

    def detect_encoding(erb_source)
      first_line = erb_source.lines.first

      if first_line.include?('-*-') && first_line.include?('coding:')
        first_line.split('coding: ').last.split(' ').first.upcase
      else
        'UTF-8'
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
