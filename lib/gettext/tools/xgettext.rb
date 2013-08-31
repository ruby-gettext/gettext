# -*- coding: utf-8 -*-
#
# Copyright (C) 2012  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2012  Kouhei Sutou <kou@clear-code.com>
# Copyright (C) 2003-2010  Masao Mutoh
# Copyright (C) 2001,2002  Yasushi Shoji, Masao Mutoh
#
# License: Ruby's or LGPL
#
# This library is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require "pathname"
require "optparse"
require "locale"
require "gettext"

module GetText
  module Tools
    class XGetText
      class << self
        def run(*arguments)
          new.run(*arguments)
        end

        # Adds a parser to the default parser list.
        #
        # @param (see #add_parser)
        # @return [void]
        #
        # @see #add_parser
        def add_parser(parser)
          @@default_parsers.unshift(parser)
        end
      end

      include GetText

      bindtextdomain("gettext")

      # @api private
      @@default_parsers = []
      builtin_parser_info_list = [
        ["glade", "GladeParser"],
        ["erb", "ErbParser"],
        # ["ripper", "RipperParser"],
        ["ruby", "RubyParser"] # Default parser.
      ]
      builtin_parser_info_list.each do |f, klass|
        begin
          require "gettext/tools/parser/#{f}"
          @@default_parsers << GetText.const_get(klass)
        rescue
          $stderr.puts(_("'%{klass}' is ignored.") % {:klass => klass})
          $stderr.puts($!) if $DEBUG
        end
      end

      # @return [Hash<Symbol, Object>] Options for parsing. Options
      #   are depend on each parser.
      # @see RubyParser#parse
      # @see ErbParser#parse
      attr_reader :parse_options

      def initialize #:nodoc:
        @parsers = @@default_parsers.dup

        @input_files = nil
        @output = nil

        @package_name = nil
        @package_version = nil
        @msgid_bugs_address = nil
        @copyright_holder = nil
        @output_encoding = nil

        @parse_options = {}
      end

      # The parser object requires to have target?(path) and
      # parse(path) method.
      #
      # @example How to add your parser
      #   require "gettext/tools/xgettext"
      #   class FooParser
      #     def target?(path)
      #       File.extname(path) == ".foo"  # *.foo file only.
      #     end
      #     def parse(path, options={})
      #       po = []
      #       # Simple entry
      #       entry = POEntry.new(:normal)
      #       entry.msgid = "hello"
      #       entry.references = ["foo.rb:200", "bar.rb:300"]
      #       entry.add_comment("Comment for the entry")
      #       po << entry
      #       # Plural entry
      #       entry = POEntry.new(:plural)
      #       entry.msgid = "An apple"
      #       entry.msgid_plural = "Apples"
      #       entry.references = ["foo.rb:200", "bar.rb:300"]
      #       po << entry
      #       # Simple entry with the entry context
      #       entry = POEntry.new(:msgctxt)
      #       entry.msgctxt = "context"
      #       entry.msgid = "hello"
      #       entry.references = ["foo.rb:200", "bar.rb:300"]
      #       po << entry
      #       # Plural entry with the message context.
      #       entry = POEntry.new(:msgctxt_plural)
      #       entry.msgctxt = "context"
      #       entry.msgid = "An apple"
      #       entry.msgid_plural = "Apples"
      #       entry.references = ["foo.rb:200", "bar.rb:300"]
      #       po << entry
      #       return po
      #     end
      #   end
      #
      #   GetText::Tools::XGetText.add_parser(FooParser.new)
      #
      # @param [#target?, #parse] parser
      #   It parses target file and extracts translate target entries from the
      #   target file. If there are multiple target files, parser.parse is
      #   called multiple times.
      # @return [void]
      def add_parser(parser)
        @parsers.unshift(parser)
      end

      def generate_pot_header # :nodoc:
        time = now.strftime("%Y-%m-%d %H:%M%z")

        <<EOH
# SOME DESCRIPTIVE TITLE.
# Copyright (C) YEAR #{@copyright_holder}
# This file is distributed under the same license as the #{@package_name} package.
# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
#
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: #{@package_name} #{@package_version}\\n"
"Report-Msgid-Bugs-To: #{@msgid_bugs_address}\\n"
"POT-Creation-Date: #{time}\\n"
"PO-Revision-Date: #{time}\\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
"Language-Team: LANGUAGE <LL@li.org>\\n"
"Language: \\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=#{@output_encoding}\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\\n"
EOH
      end

      def generate_pot(paths) # :nodoc:
        po = parse(paths)
        entries = []
        po.each do |target|
          entries << encode(target.to_s)
        end
        entries.join("\n")
      end

      def parse(paths) # :nodoc:
        po = []
        paths = [paths] if paths.kind_of?(String)
        paths.each do |path|
          begin
            parse_path(path, po)
          rescue
            puts(_("Error parsing %{path}") % {:path => path})
            raise
          end
        end
        po
      end

      def check_command_line_options(*options) # :nodoc:
        input_files, output = parse_arguments(*options)

        if input_files.empty?
          raise ArgumentError, _("no input files")
        end

        output ||= STDOUT

        @input_files = input_files
        @output = output

        @package_name ||= "PACKAGE"
        @package_version ||= "VERSION"
        @msgid_bugs_address ||= ""
        @copyright_holder ||= "THE PACKAGE'S COPYRIGHT HOLDER"
      end

      def parse_arguments(*options) #:nodoc:
        output = nil

        parser = OptionParser.new
        banner = _("Usage: %s input.rb [-r parser.rb] [-o output.pot]") % $0
        parser.banner = banner
        parser.separator("")
        description = _("Extract translatable strings from given input files.")
        parser.separator(description)
        parser.separator("")
        parser.separator(_("Specific options:"))

        parser.on("-o", "--output=FILE",
                  _("write output to specified file")) do |out|
          output = out
        end

        parser.on("--package-name=PACKAGE",
                  _("set package name in output")) do |out|
          @package_name = out
        end

        parser.on("--package-version=VERSION",
                  _("set package version in output")) do |out|
          @package_version = out
        end

        parser.on("--msgid-bugs-address=EMAIL",
                  _("set report address for msgid bugs")) do |out|
          @msgid_bugs_address = out
        end

        parser.on("--copyright-holder=STRING",
                  _("set copyright holder in output")) do |out|
          @copyright_holder = out
        end

        parser.on("--output-encoding=ENCODING",
                  _("set encoding for output")) do |encoding|
          @output_encoding = encoding
        end

        parser.on("-r", "--require=library",
                  _("require the library before executing xgettext")) do |out|
          require out
        end

        parser.on("-c", "--add-comments[=TAG]",
                  _("If TAG is specified, place comment blocks starting with TAG and precedding keyword lines in output file"),
                  _("If TAG is not specified, place all comment blocks preceing keyword lines in output file"),
                  _("(default: %s)") % _("no TAG")) do |tag|
          @parse_options[:comment_tag] = tag
        end

        parser.on("-d", "--debug", _("run in debugging mode")) do
          $DEBUG = true
        end

        parser.on("-h", "--help", _("display this help and exit")) do
          puts(parser.help)
          exit(true)
        end

        parser.on_tail("--version", _("display version information and exit")) do
          puts(GetText::VERSION)
          exit(true)
        end

        parser.parse!(options)

        [options, output]
      end

      def run(*options)  # :nodoc:
        check_command_line_options(*options)

        @output_encoding ||= "UTF-8"
        pot = generate_pot_header
        pot << "\n"
        pot << generate_pot(@input_files)

        if @output.is_a?(String)
          File.open(File.expand_path(@output), "w+") do |file|
            file.puts(pot)
          end
        else
          @output.puts(pot)
        end
        self
      end

      private
      def now
        Time.now
      end

      def parse_path(path, po)
        @parsers.each do |parser|
          next unless parser.target?(path)

          # For backward compatibility
          if parser.method(:parse).arity == 1 or @parse_options.empty?
            extracted_po = parser.parse(path)
          else
            extracted_po = parser.parse(path, @parse_options)
          end
          extracted_po.each do |po_entry|
            if po_entry.kind_of?(Array)
              po_entry = POEntry.new_from_ary(po_entry)
            end

            if po_entry.msgid.empty?
              warn _("Warning: The empty \"\" msgid is reserved by " +
                       "gettext. So gettext(\"\") doesn't returns " +
                       "empty string but the header entry in po file.")
              # TODO: add pommesage.reference to the pot header as below:
              # # SOME DESCRIPTIVE TITLE.
              # # Copyright (C) YEAR THE COPYRIGHT HOLDER
              # # This file is distributed under the same license as the PACKAGE package.
              # # FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
              # #
              # #: test/test_gettext.rb:65
              # #, fuzzy
              # "#: test/test_gettext.rb:65" line is added.
              next
            end

            if @output.is_a?(String)
              base_path = Pathname.new(@output).dirname.expand_path
              po_entry.references = po_entry.references.collect do |reference|
                path, line, = reference.split(/:(\d+)\z/, 2)
                absolute_path = Pathname.new(path).expand_path
                begin
                  path = absolute_path.relative_path_from(base_path).to_s
                rescue ArgumentError
                  raise # Should we ignore it?
                end
                "#{path}:#{line}"
              end
            end

            # Save the previous target
            if po.empty?
              existing = nil
            else
              entry = po.find {|t| t.mergeable?(po_entry)}
              existing = po.index(entry)
            end

            if existing
              po_entry = po[existing].merge(po_entry)
              po[existing] = po_entry
            else
              po << po_entry
            end
          end
          break
        end
      end

      def encode(string)
        string.encode(@output_encoding)
      end
    end
  end
end
