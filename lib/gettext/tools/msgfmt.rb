# -*- coding: utf-8 -*-

=begin
  rmsgfmt.rb - Generate a .mo

  Copyright (C) 2012      Haruka Yoshihara
  Copyright (C) 2003-2009 Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.
=end

require "optparse"
require "fileutils"
require "gettext"
require "gettext/tools/poparser"
require "rbconfig"

module GetText
  module Tools
    class MsgFmt  #:nodoc:
      include GetText

      bindtextdomain("rgettext")

      def initialize
        @input_file = nil
        @output_file = nil
      end

      def run(*options) # :nodoc:
        initialize_arguments(*options)

        parser = PoParser.new
        data = MoFile.new

        parser.parse_file(@input_file, data)
        data.save_to_file(@output_file)
      end

      def initialize_arguments(*options) # :nodoc:
        input_file, output_file = parse_commandline_options(*options)

        if input_file.nil?
          raise(ArgumentError, _("no input files specified."))
        end

        if output_file.nil?
          output_file = "messages.mo"
        end

        @input_file = input_file
        @output_file = output_file
      end

      def parse_commandline_options(*options)
        output_file = nil

        parser = OptionParser.new
        parser.banner = _("Usage: %s input.po [-o output.mo]" % $0)
        parser.separator("")
        description = _("Generate binary message catalog from textual " +
                          "translation description.")
        parser.separator(description)
        parser.separator("")
        parser.separator(_("Specific options:"))

        parser.on("-o", "--output=FILE",
                _("write output to specified file")) do |out|
          output_file = out
        end

        parser.on_tail("--version", _("display version information and exit")) do
          puts(VERSION)
          exit(true)
        end
        parser.parse!(options)

        input_file = options[0]
        [input_file, output_file]
      end
    end
  end

  # Create a mo-file from a target file(po-file).
  # You must specify a path of a target file in options.
  # If a path of a mo-file is not specified in options, a mo-file is
  # created as "messages.mo" in the current directory.
  # @param [Array<String>] options options for rmsgfmt.
  # @return [MoFile] the MoFile object.
  def rmsgfmt(*options)
    rmsgfmt = Tools::MsgFmt.new
    rmsgfmt.run(*options)
  end

  module_function :rmsgfmt
end
