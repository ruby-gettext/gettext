# Copyright (C) 2014  Kouhei Sutou <kou@clear-code.com>
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

require "optparse"
require "gettext"
require "gettext/po_parser"
require "gettext/po"

module GetText
  module Tools
    class MsgCat
      class << self
        # (see #run)
        #
        # This method is provided just for convenience. It equals to
        # `new.run(*command_line)`.
        def run(*command_line)
          new.run(*command_line)
        end
      end

      # Concatenates po-files.
      #
      # @param [Array<String>] command_line
      #   The command line arguments for rmsgcat.
      # @return [void]
      def run(*command_line)
        config = Config.new
        config.parse(command_line)

        parser = POParser.new
        output_po = PO.new
        output_po.order = config.order
        merger = Merger.new(output_po, config)
        config.pos.each do |po_file_name|
          po = PO.new
          parser.parse_file(po_file_name, po)
          merger.merge(po)
        end

        output_po_string = output_po.to_s(config.po_format_options)
        if config.output.is_a?(String)
          File.open(File.expand_path(config.output), "w") do |file|
            file.print(output_po_string)
          end
        else
          puts(output_po_string)
        end
      end

      # @private
      class Merger
        def initialize(output_po, config)
          @output_po = output_po
          @config = config
        end

        def merge(po)
          po.each do |entry|
            id = [entry.msgctxt, entry.msgid]
            @output_po[*id] = merge_definition(entry)
          end
        end

        private
        def merge_definition(entry)
          msgid = entry.msgid
          msgctxt = entry.msgctxt
          id = [msgctxt, msgid]

          if @output_po.has_key?(*id)
            merge_entry(@output_po[*id], entry)
          else
            entry
          end
        end

        def merge_entry(base_entry, new_entry)
          if base_entry.header?
            return merge_header(base_entry, new_entry)
          end

          if base_entry.fuzzy?
            if new_entry.fuzzy?
              return base_entry
            else
              return new_entry
            end
          end

          base_entry
        end

        def merge_header(base_entry, new_entry)
          base_entry
        end
      end

      # @private
      class Config
        include GetText

        bindtextdomain("gettext")

        # @return [Array<String>] The input PO file names.
        attr_accessor :pos

        # @return [String] The output file name.
        attr_accessor :output

        # @return [:reference, :msgid] The sort key.
        attr_accessor :order

        # @return [Hash] The PO format options.
        # @see PO#to_s
        # @see POEntry#to_s
        attr_accessor :po_format_options

        def initialize
          @pos = []
          @output = nil
          @order = nil
          @po_format_options = {}
        end

        def parse(command_line)
          parser = create_option_parser
          @pos = parser.parse(command_line)
        end

        private
        def create_option_parser
          parser = OptionParser.new
          parser.version = GetText::VERSION
          parser.banner = _("Usage: %s [OPTIONS] PO_FILE1 PO_FILE2 ...") % $0
          parser.separator("")
          parser.separator(_("Concatenates and merges PO files."))
          parser.separator("")
          parser.separator(_("Specific options:"))

          parser.on("-o", "--output=FILE",
                    _("Write output to specified file"),
                    _("(default: the standard output)")) do |output|
            @output = output
          end

          parser.on("--sort-by-msgid",
                    _("Sort output by msgid")) do
            @order = :msgid
          end

          parser.on("--sort-by-location",
                    _("Sort output by location")) do
            @order = :reference
          end

          parser.on("--sort-by-file",
                    _("Sort output by location"),
                    _("It is same as --sort-by-location"),
                    _("Just for GNU gettext's msgcat compatibility")) do
            @order = :reference
          end

          parser.on("--[no-]sort-output",
                    _("Sort output by msgid"),
                    _("It is same as --sort-by-msgid"),
                    _("Just for GNU gettext's msgcat compatibility")) do |sort|
            @order = sort ? :msgid : nil
          end

          parser.on("--no-location",
                    _("Remove location information")) do |boolean|
            @po_format_options[:include_reference_comment] = boolean
          end

          parser.on("--no-all-comments",
                    _("Remove all comments")) do |boolean|
            @po_format_options[:include_all_comments] = boolean
          end

          parser
        end
      end
    end
  end
end
