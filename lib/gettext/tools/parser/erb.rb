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
  module ErbParser
    extend self

    @config = {
      :extnames => ['.rhtml', '.erb']
    }

    # Sets some preferences to parse ERB files.
    # * config: a Hash of the config. It can takes some values below:
    #   * :extnames: An Array of target files extension. Default is [".rhtml"].
    def init(config)
      config.each{|k, v|
  @config[k] = v
      }
    end

    MAGIC_COMMENT = /\A#.*?coding[:=].*?\n/

    def parse(file) # :nodoc:
      content = IO.read(file)
      src = ERB.new(content).src

      if src.respond_to?(:encode)
        # Force the src encoding back to the encoding in magic comment
        # or original content.
        encoding = find_encoding(src)
        encoding = content.encoding if encoding.nil?
        src.force_encoding(encoding)

        # Remove magic comment prepended by erb in Ruby 1.9.
        src = src.gsub(MAGIC_COMMENT, "")
      end

      erb = src.split(/$/)
      RubyParser.parse_lines(file, erb)
    end

    def find_encoding(erb_source)
      if /\A#coding:(.*)\n/ =~ erb_source
        encoding = $1
      else
        encoding = nil
      end
    end

    def target?(file) # :nodoc:
      @config[:extnames].each do |v|
  return true if File.extname(file) == v
      end
      false
    end
  end
end

if __FILE__ == $0
  # ex) ruby glade.rhtml foo.rhtml  bar.rhtml
  ARGV.each do |file|
    p GetText::ErbParser.parse(file)
  end
end
