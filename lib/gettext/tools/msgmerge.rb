# -*- coding: utf-8 -*-
#
# Copyright (C) 2012  Kouhei Sutou <kou@clear-code.com>
# Copyright (C) 2005-2009 Masao Mutoh
# Copyright (C) 2005,2006 speakillof
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
require "levenshtein"
require "gettext"
require "gettext/tools/poparser"
require "gettext/tools/po"

# TODO: MsgMerge should use POEntry to generate PO content.

module GetText
  module Tools
    class MsgMerge
      class PoData  #:nodoc:

        attr_reader :po

        def initialize
          @po = PO.new
        end

        def set_comment(msgid, comments, msgctxt=nil)
          entry = generate_entry(msgid)

          if msgid == :last
            entry.comment = comments
            return
          end

          comments.each_line do |_line|
            line = _line.chomp
            entry = parse_comment(line, entry)
          end
        end

        def msgstr(msgid)
          self[msgid]
        end

        def comment(msgid)
          msgctxt, msgid, _ = split_msgid(msgid)
          id = [msgctxt, msgid]
          entry = @po[*id]
          return nil if entry.nil?

          formatted_comments = entry.format_translator_comment
          formatted_comments << entry.format_extracted_comment
          formatted_comments << entry.format_reference_comment
          formatted_comments << entry.format_flag_comment
          formatted_comments << entry.format_previous_msgid_comment

          unless entry.comment.nil?
            formatted_comments = entry.format_comment("#", entry.comment)
          end

          formatted_comments.chomp
        end

        def [](msgid)
          msgctxt, msgid, _ = split_msgid(msgid)
          @po[msgctxt, msgid].msgstr
        end

        def []=(msgid, value)
          msgctxt, msgid, msgid_plural = split_msgid(msgid)
          id = [msgctxt, msgid]

          if value.instance_of?(POEntry)
            @po[*id] = value
            return value
          end

          msgstr = value
          if @po.has_key?(*id)
            @po[*id] = msgstr
            @po[*id].msgctxt = msgctxt
            @po[*id].msgid_plural = msgid_plural
          else
            type = detect_entry_type(msgctxt, msgid_plural)
            entry = POEntry.new(type)
            entry.msgctxt = msgctxt
            entry.msgid = msgid
            entry.msgid_plural = msgid_plural
            entry.msgstr = msgstr
            @po[*id] = entry
            entry
          end
        end

        def each_msgid
          msgids.each do |id|
            next if id.kind_of?(Symbol) or id.empty?
            yield(id)
          end
        end

        def msgids
          @po.collect do |entry|
            msgctxt = entry.msgctxt
            msgid = entry.msgid
            generate_original_string(msgctxt, msgid)
          end
        end

        def msgid?(msgid)
          return false if msgid.kind_of?(Symbol)
          return true if msgid.empty?
          msgctxt, msgid, _ = split_msgid(msgid)
          @po.has_key?(msgctxt, msgid)
        end

        # Is it necessary to implement this method?
        def search_msgid_fuzzy(msgid, used_msgids)
          nil
        end

        def nplurals
          return 0 if @po[""].msgstr.nil?

          if /\s*nplurals\s*=\s*(\d+)/ =~ @po[""].msgstr
            return $1.to_i
          else
            return 0
          end
        end

        def generate_po
          @po.to_s
        end

        def generate_po_entry(msgid)
          msgctxt, msgid, _ = split_msgid(msgid)
          @po[msgctxt, msgid].to_s
        end

        def __conv(str)
          s = ""

          if str.count("\n") > 1
            s << '""' << "\n"
            str.each_line do |line|
              s << '"' << escape(line) << '"' << "\n"
            end
          else
            s << '"' << escape(str) << '"'
          end

          s.rstrip
        end

        def escape(string)
          POEntry.escape(string)
        end

        private
        def split_msgid(msgid)
          return [nil, msgid, nil] if msgid == :last
          return [nil, "", nil] if msgid.empty?
          msgctxt, msgid = msgid.split("\004", 2)
          if msgid.nil?
            msgid = msgctxt
            msgctxt = nil
          end
          msgid, msgid_plural = msgid.split("\000", 2)
          [msgctxt, msgid, msgid_plural]
        end

        def generate_original_string(msgctxt, msgid)
          return msgid if msgid == :last
          original_string = ""
          msgid_plural = @po[msgctxt, msgid].msgid_plural
          original_string << "#{msgctxt}\004" unless msgctxt.nil?
          original_string << msgid
          original_string << "\000#{msgid_plural}" unless msgid_plural.nil?
          original_string
        end

        def detect_entry_type(msgctxt, msgid_plural)
          if msgctxt.nil?
            if msgid_plural.nil?
              :normal
            else
              :plural
            end
          else
            if msgid_plural.nil?
              :msgctxt
            else
              :msgctxt_plural
            end
          end
        end

        def generate_entry(msgid)
          msgctxt, msgid, _ = split_msgid(msgid)
          id = [msgctxt, msgid]
          @po[*id] = nil unless @po.has_key?(*id)
          entry = @po[*id]

          entry.translator_comment = ""
          entry.extracted_comment = ""
          entry.references = []
          entry.flag = ""
          entry.previous_msgid = ""
          entry
        end

        def parse_comment(line, entry)
          if line == "#"
            entry.translator_comment << ""
          elsif /\A(#.)\s*(.*)\z/ =~ line
            mark = $1
            content = $2
            case mark
            when POParser::TRANSLATOR_COMMENT_MARK
              entry.translator_comment << "#{content}\n"
            when POParser::EXTRACTED_COMMENT_MARK
              entry.extracted_comment << "#{content}\n"
            when POParser::REFERENCE_COMMENT_MARK
              entry.references << content
            when POParser::FLAG_MARK
              entry.flag << "#{content}\n"
            when POParser::PREVIOUS_MSGID_COMMENT_MARK
              entry.previous_msgid << "#{content.gsub(/\Amsgid\s+/, "")}\n"
            else
              entry.comment << line
            end
          end
          entry
        end
      end

      class Merger #:nodoc:
        # Merge the reference with the definition: take the #. and
        #  #: comments from the reference, take the # comments from
        # the definition, take the msgstr from the definition.  Add
        # this merged entry to the output message list.

        POT_DATE_EXTRACT_RE = /POT-Creation-Date:\s*(.*)?\s*$/
        POT_DATE_RE = /POT-Creation-Date:.*?$/

        def merge(definition, reference)
          result = GetText::PO.new

          reference.each do |entry|
            msgid = entry.msgid
            msgctxt = entry.msgctxt
            id = [msgctxt, msgid]

            if definition.has_key?(*id)
              result[*id] = merge_entry(definition[*id], entry)
              next
            end

            if msgctxt.nil?
              same_msgid_entry = find_by_msgid(definition, msgid)
              if not same_msgid_entry.nil? and not same_msgid_entry.msgctxt.nil?
                result[nil, msgid] = merge_fuzzy_entry(same_msgid_entry, entry)
                next
              end
            end

            fuzzy_entry = find_fuzzy_entry(definition, msgid, msgctxt)
            unless fuzzy_entry.nil?
              result[*id] = merge_fuzzy_entry(fuzzy_entry, entry)
              next
            end

            result[*id] = entry
          end

          add_obsolete_entry(result, definition)
          result
        end

        def merge_entry(definition_entry, reference_entry)
          if definition_entry.msgid.empty? and definition_entry.msgctxt.nil?
            new_header = merge_header(definition_entry, reference_entry)
            return new_header
          end

          if definition_entry.flag == "fuzzy"
            entry = definition_entry
            entry.flag = "fuzzy"
            return entry
          end

          entry = reference_entry
          entry.translator_comment = definition_entry.translator_comment
          entry.previous_msgid = nil

          unless definition_entry.msgid_plural == reference_entry.msgid_plural
            entry.flag = "fuzzy"
          end

          entry.msgstr = definition_entry.msgstr
          entry
        end

        def merge_header(old_header, new_header)
          header = old_header
          if POT_DATE_EXTRACT_RE =~ new_header.msgstr
            create_date = $1
            pot_creation_date = "POT-Creation-Date: #{create_date}"
            header.msgstr = header.msgstr.gsub(POT_DATE_RE, pot_creation_date)
          end
          header.flag = nil
          header
        end

        def find_by_msgid(entries, msgid)
          same_msgid_entries = entries.find_all do |entry|
            entry.msgid == msgid
          end
          same_msgid_entries = same_msgid_entries.sort_by do |entry|
            entry.msgctxt
          end
          same_msgid_entries.first
        end

        def merge_fuzzy_entry(fuzzy_entry, entry)
          merged_entry = merge_entry(fuzzy_entry, entry)
          merged_entry.flag = "fuzzy"
          merged_entry
        end

        MAX_FUZZY_DISTANCE = 0.5 # XXX: make sure that its value is proper.

        def find_fuzzy_entry(definition, msgid, msgctxt)
          min_distance_entry = nil
          min_distance = MAX_FUZZY_DISTANCE

          same_msgctxt_entries = definition.find_all do |entry|
            entry.msgctxt == msgctxt
          end
          same_msgctxt_entries.each do |entry|
            distance = Levenshtein.normalized_distance(entry.msgid, msgid)
            if min_distance > distance
              min_distance = distance
              min_distance_entry = entry
            end
          end

          min_distance_entry
        end

        def add_obsolete_entry(result, definition)
          obsolete_entry = generate_obsolete_entry(result, definition)
          unless obsolete_entry.nil?
            result[:last] = obsolete_entry
          end
          result
        end

        def generate_obsolete_entry(result, definition)
          obsolete_entry = nil

          obsolete_entries = extract_obsolete_entries(result, definition)
          unless obsolete_entries.empty?
            obsolete_comment = ""

            obsolete_entries.each do |entry|
              obsolete_comment << entry.to_s
            end
            obsolete_entry = POEntry.new(:normal)
            obsolete_entry.msgid = :last
            obsolete_entry.comment = obsolete_comment
          end
          obsolete_entry
        end

        def extract_obsolete_entries(result, definition)
          obsolete_entries = []
          definition.each do |entry|
            id = [entry.msgctxt, entry.msgid]
            unless result.has_key?(*id)
              obsolete_entries << entry
            end
          end
          obsolete_entries
        end
      end

      class Config #:nodoc:

        attr_accessor :defpo, :refpot, :output, :fuzzy, :update

        # update mode options
        attr_accessor :backup, :suffix

        # The result is written back to def.po.
        #       --backup=CONTROL        make a backup of def.po
        #       --suffix=SUFFIX         override the usual backup suffix
        # The version control method may be selected
        # via the --backup option or through
        # the VERSION_CONTROL environment variable.  Here are the values:
        #   none, off       never make backups (even if --backup is given)
        #   numbered, t     make numbered backups
        #   existing, nil   numbered if numbered backups exist, simple otherwise
        #   simple, never   always make simple backups
        # The backup suffix is `~', unless set with --suffix or
        # the SIMPLE_BACKUP_SUFFIX environment variable.

        def initialize
          @output = nil
          @fuzzy = nil
          @update = nil
          @backup = ENV["VERSION_CONTROL"]
          @suffix = ENV["SIMPLE_BACKUP_SUFFIX"] || "~"
          @input_dirs = ["."]
        end
      end

      class << self
        # Merge a po-file inluding translated messages and a new pot-file.
        # @param [Array<String>] arguments arguments for rmsgfmt.
        # @return [void]
        def run(*arguments)
          new.run(*arguments)
        end
      end

      include GetText

      bindtextdomain("gettext")

      # constant values
      VERSION = GetText::VERSION

      def check_command_line_options(*options) #:nodoc:
        options, output = parse_arguments(*options)

        config = Config.new
        config.output = output
        config.defpo = options[0]
        config.refpot = options[1]

        if config.defpo.nil?
          raise ArgumentError, _("definition po is not given.")
        elsif config.refpot.nil?
          raise ArgumentError, _("reference pot is not given.")
        end

        config
      end

      def parse_arguments(*options) #:nodoc:
        parser = OptionParser.new
        parser.banner = _("Usage: %s def.po ref.pot [-o output.pot]") % $0
        #parser.summary_width = 80
        parser.separator("")
        description = _("Merges two Uniforum style .po files together. " +
                          "The def.po file is an existing PO file with " +
                          "translations. The ref.pot file is the last " +
                          "created PO file with up-to-date source " +
                          "references. ref.pot is generally created by " +
                          "rgettext.")
        parser.separator(description)
        parser.separator("")
        parser.separator(_("Specific options:"))

        output = nil

        parser.on("-o", "--output=FILE",
                _("write output to specified file")) do |out|
          output = out
        end

        #parser.on("-F", "--fuzzy-matching")

        parser.on("-h", "--help", _("Display this help and exit")) do
          puts(parser.help)
          exit(true)
        end

        parser.on_tail("--version", _("display version information and exit")) do
          puts(VERSION)
          exit(true)
        end

        parser.parse!(options)

        [options, output]
      end

      def run(*options) #:nodoc:
        config = check_command_line_options(*options)

        parser = POParser.new
        parser.ignore_fuzzy = false
        defpo = parser.parse_file(config.defpo, PO.new)
        refpot = parser.parse_file(config.refpot, PO.new)

        merger = Merger.new
        result = merger.merge(defpo, refpot)
        p result if $DEBUG
        print result.generate_po if $DEBUG

        if config.output.is_a?(String)
          File.open(File.expand_path(config.output), "w+") do |file|
            file.write(result.to_s)
          end
        else
          puts(result.to_s)
        end
      end
    end
  end
end
