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
        # From GNU gettext source.
        #
        # Merge the reference with the definition: take the #. and
        #  #: comments from the reference, take the # comments from
        # the definition, take the msgstr from the definition.  Add
        # this merged entry to the output message list.

        DOT_COMMENT_RE = /\A#\./
        SEMICOLON_COMMENT_RE = /\A#\:/
        FUZZY_RE = /\A#\,/
        NOT_SPECIAL_COMMENT_RE = /\A#([^:.,]|\z)/

        CRLF_RE = /\r?\n/
        POT_DATE_EXTRACT_RE = /POT-Creation-Date:\s*(.*)?\s*$/
        POT_DATE_RE = /POT-Creation-Date:.*?$/

        def merge(definition, reference)
          definition.each_msgid do |msgid|
            msgstr = definition[msgid] || ""
            definition[msgid] = msgstr
          end

          reference.each_msgid do |msgid|
            msgstr = reference[msgid] || ""
            reference[msgid] = msgstr
          end

          # deep copy
          result = Marshal.load( Marshal.dump(reference) )

          used = []
          merge_header(result, definition)

          result.each_msgid do |msgid|
            if definition.msgid?(msgid)
              used << msgid
              merge_message(msgid, result, msgid, definition)
            elsif other_msgid = definition.search_msgid_fuzzy(msgid, used)
              used << other_msgid
              merge_fuzzy_message(msgid, result, other_msgid, definition)
            elsif msgid.index("\000") and (reference.msgstr(msgid).gsub("\000", "").empty?)
              # plural
              result[msgid] = ([""] * definition.nplurals).join("\000")
            else
              change_reference_comment(msgid, result)
            end
          end

          ###################################################################
          # msgids which are not used in reference are handled as obsolete. #
          ###################################################################
          last_comment = result.comment(:last) || ""
          definition.each_msgid do |msgid|
            unless used.include?(msgid)
              last_comment << "\n"
              last_comment << definition.generate_po_entry(msgid).strip.gsub(/^/, "#. ")
              last_comment << "\n"
            end
          end
          result.set_comment(:last, last_comment) unless last_comment.empty?

          result
        end

        def merge_message(msgid, target, def_msgid, definition)
          merge_comment(msgid, target, def_msgid, definition)

          ############################################
          # check mismatch of msgid and msgid_plural #
          ############################################
          def_msgstr = definition[def_msgid]
          if msgid.index("\000")
            if def_msgstr.index("\000")
              # OK
              target[msgid] = def_msgstr
            else
              # NG
              strings = []
              definition.nplurals.times do
                strings << def_msgstr
              end
              target[msgid] = strings.join("\000")
            end
          else
            if def_msgstr.index("\000")
              # NG
              target[msgid] = def_msgstr.split("\000")[0]
            else
              # OK
              target[msgid] = def_msgstr
            end
          end
        end

        # for the future
        def merge_fuzzy_message(msgid, target, def_msgid, definition)
          merge_message(msgid, target, def_msgid, definition)
        end

        def merge_comment(msgid, target, def_msgid, definition)
          ref_comment = target.comment(msgid)
          def_comment = definition.comment(def_msgid)

          normal_comment = []
          dot_comment = []
          semi_comment = []
          is_fuzzy = false

          def_comment.split(CRLF_RE).each do |l|
            if NOT_SPECIAL_COMMENT_RE =~ l
              normal_comment << l
            end
          end

          ref_comment.split(CRLF_RE).each do |l|
            if DOT_COMMENT_RE =~ l
              dot_comment << l
            elsif SEMICOLON_COMMENT_RE =~ l
              semi_comment << l
            elsif FUZZY_RE =~ l
              is_fuzzy = true if msgid != ""
            end
          end

          str = format_comment(normal_comment, dot_comment, semi_comment, is_fuzzy)
          target.set_comment(msgid, str)
        end

        def change_reference_comment(msgid, podata)
          normal_comment = []
          dot_comment = []
          semi_comment = []
          is_fuzzy = false

          podata.comment(msgid).split(CRLF_RE).each do |l|
            if DOT_COMMENT_RE =~ l
              dot_comment << l
            elsif SEMICOLON_COMMENT_RE =~ l
              semi_comment << l
            elsif FUZZY_RE =~ l
              is_fuzzy = true
            else
              normal_comment << l
            end
          end

          str = format_comment(normal_comment, dot_comment, semi_comment, is_fuzzy)
          podata.set_comment(msgid, str)
        end

        def format_comment(normal_comment, dot_comment, semi_comment, is_fuzzy)
          str = ""

          str << normal_comment.join("\n").gsub(/^#(\s*)/) do |sss|
            if $1 == ""
              "# "
            else
              sss
            end
          end
          if normal_comment.size > 0
            str << "\n"
          end

          str << dot_comment.join("\n").gsub(/^#.(\s*)/) do |sss|
            if $1 == ""
              "#. "
            else
              sss
            end
          end
          if dot_comment.size > 0
            str << "\n"
          end

          str << semi_comment.join("\n").gsub(/^#:\s*/, "#: ")
          if semi_comment.size > 0
            str << "\n"
          end

          if is_fuzzy
            str << "#, fuzzy\n"
          end

          str
        end

        def merge_header(target, definition)
          merge_comment("", target, "", definition)

          msg = target.msgstr("")
          def_msg = definition.msgstr("")
          if POT_DATE_EXTRACT_RE =~ msg
            time = $1
            def_msg = def_msg.sub(POT_DATE_RE, "POT-Creation-Date: #{time}")
          end

          target[""] = def_msg
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
        defpo = parser.parse_file(config.defpo, PoData.new)
        refpot = parser.parse_file(config.refpot, PoData.new)

        merger = Merger.new
        result = merger.merge(defpo, refpot)
        p result if $DEBUG
        print result.generate_po if $DEBUG

        if config.output.is_a?(String)
          File.open(File.expand_path(config.output), "w+") do |file|
            file.write(result.generate_po)
          end
        else
          puts(result.generate_po)
        end
      end
    end
  end
end
