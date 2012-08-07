#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

=begin
  rgettext.rb - Generate a .pot file.

  Copyright (C) 2012  Haruka Yoshihara
  Copyright (C) 2003-2010  Masao Mutoh
  Copyright (C) 2001,2002  Yasushi Shoji, Masao Mutoh

      Yasushi Shoji    <yashi at atmark-techno.com>
      Masao Mutoh      <mutomasa at gmail.com>
      Haruka Yoshihara <yoshihara@clear-code.com>

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.
=end

require "optparse"
require "gettext"
require "rbconfig"

module GetText
  class RGetText #:nodoc:
    include GetText

    bindtextdomain("rgettext")

    def initialize
      @ex_parsers = []
      parsers = [
        ["glade.rb", "GladeParser"],
        ["erb.rb", "ErbParser"],
        # ["ripper.rb", "RipperParser"],
        ["ruby.rb", "RubyParser"] # Default parser.
      ]
      parsers.each do |f, klass|
        begin
          require "gettext/tools/parser/#{f}"
          @ex_parsers << GetText.const_get(klass)
        rescue
          $stderr.puts(_("'%{klass}' is ignored.") % {:klass => klass})
          $stderr.puts($!) if $DEBUG
        end
      end
    end

    # How to add your option parser
    # The option parser module requires to have target?(file) and
    # parser(file, ary) method.
    #
    #  require "gettext/tools/rgettext"
    #  module FooParser
    #    module_function
    #    def target?(file)
    #      File.extname(file) == ".foo"  # *.foo file only.
    #    end
    #    def parse(file)
    #      :
    #      ary = []
    #      # Simple message
    #      po = PoMessage.new(:normal)
    #      po.msgid = "hello"
    #      po.sources = ["foo.rb:200", "bar.rb:300"]
    #      po.add_comment("Comment for the message")
    #      ary << po
    #      # Plural message
    #      po = PoMessage.new(:plural)
    #      po.msgid = "An apple"
    #      po.msgid_plural = "Apples"
    #      po.sources = ["foo.rb:200", "bar.rb:300"]
    #      ary << po
    #      # Simple message with the message context
    #      po = PoMessage.new(:msgctxt)
    #      po.msgctxt = "context"
    #      po.msgid = "hello"
    #      po.sources = ["foo.rb:200", "bar.rb:300"]
    #      ary << po
    #      # Plural message with the message context.
    #      po = PoMessage.new(:msgctxt_plural)
    #      po.msgctxt = "context"
    #      po.msgid = "An apple"
    #      po.msgid_plural = "Apples"
    #      po.sources = ["foo.rb:200", "bar.rb:300"]
    #      ary << po
    #      return ary
    #    end
    #  end
    #
    #  GetText::RGetText.add_parser(FooParser)
    def add_parser(klass)
      @ex_parsers.insert(0, klass)
    end

    def generate_pot_header # :nodoc:
      time = Time.now.strftime("%Y-%m-%d %H:%M%z")

      <<EOH
# SOME DESCRIPTIVE TITLE.
# Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
#
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\\n"
"POT-Creation-Date: #{time}\\n"
"PO-Revision-Date: #{time}\\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
"Language-Team: LANGUAGE <LL@li.org>\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\\n"
EOH
    end

    def generate_pot(paths) # :nodoc:
      pomessages = parse(paths)
      str = ""
      pomessages.each do |target|
        str << target.to_po_str
      end
      str
    end

    def parse(paths) # :nodoc:
      pomessages = []
      paths = [paths] if paths.kind_of?(String)
      paths.each do |path|
        begin
          @ex_parsers.each do |klass|
            if klass.target?(path)
              if klass.method(:parse).arity == 1
                targets = klass.parse(path)
              else
                # For backward compatibility
                targets = klass.parse(path, [])
              end

              targets.each do |pomessage|
                if pomessage.kind_of?(Array)
                  pomessage = PoMessage.new_from_ary(pomessage)
                end

                # Save the previous target
                if pomessages.empty?
                  existing = nil
                else
                  message = pomessages.find {|t| t == pomessage}
                  existing = pomessages.index(message)
                end

                if existing
                  pomessage = pomessages[existing].merge(pomessage)
                  pomessages[existing] = pomessage
                else
                  pomessages << pomessage
                end
              end
              break
            end
          end
        rescue
          puts(_("Error parsing %{path}") % {:path => path})
          raise
        end
      end
      pomessages
    end

    # constant values
    VERSION = GetText::VERSION

    def check_options # :nodoc:
      output = STDOUT

      opts = OptionParser.new
      opts.banner = _("Usage: %s input.rb [-r parser.rb] [-o output.pot]") % $0
      opts.separator("")
      opts.separator(_("Extract translatable strings from given input files."))
      opts.separator("")
      opts.separator(_("Specific options:"))

      opts.on("-o", "--output=FILE",
              _("write output to specified file")) do |out|
        unless FileTest.exist?(out)
          output = File.new(File.expand_path(out), "w+")
        else
          $stderr.puts(_("File '%s' already exists.") % out)
          exit(false)
        end
      end

      opts.on("-r", "--require=library",
              _("require the library before executing rgettext")) do |out|
        require out
      end

      opts.on("-d", "--debug", _("run in debugging mode")) do
        $DEBUG = true
      end

      opts.on_tail("--version", _("display version information and exit")) do
        puts("#{$0} #{VERSION}")
        ruby_bin_dir = ::RbConfig::CONFIG["bindir"]
        ruby_install_name = ::RbConfig::CONFIG["RUBY_INSTALL_NAME"]
        ruby_description = "#{File.join(ruby_bin_dir, ruby_install_name)} " +
                             "#{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) " +
                             "[#{RUBY_PLATFORM}]"
        puts(ruby_description)
        exit(true)
      end

      opts.parse!(ARGV)

      if ARGV.size == 0
        puts(opts.help)
        exit(false)
      end

      [ARGV, output]
    end

    def run(paths = nil, out = STDOUT)  # :nodoc:
      if paths.is_a?(String)
        paths = [paths]
      elsif paths.nil?
        paths, out = check_options
      end
      if paths.size == 0
        raise ArgumentError, _("no input files")
      end
      if out.is_a?(String)
        File.open(File.expand_path(out), "w+") do |file|
          file.puts(generate_pot_header)
          file.puts(generate_pot(paths))
        end
      else
        out.puts(generate_pot_header)
        out.puts(generate_pot(paths))
      end
      self
    end
  end
  extend self
  # Creates a pot file from target files(ruby-script-files, .rhtml
  # files, glade-2 XML files), then output the result to out. If no
  # parameter is set, it behaves same as command line tools(rgettext).
  #
  # This method is a part of GetText.create_pofiles.
  # Usually you don't need to call this method directly.
  #
  # * paths: An Array of target file paths or nil.
  # * out: output IO or output path.
  # * Returns: self
  def rgettext(paths = nil, out = STDOUT)
    rgettext = RGetText.new
    rgettext.run(paths, out)
    self
  end
end

if $0 == __FILE__
  GetText.rgettext
#  GetText.rgettext($0, "tmp.txt")
end
