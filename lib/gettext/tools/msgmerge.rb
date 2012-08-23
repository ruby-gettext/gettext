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
require "gettext/tools/pomessage"

# TODO: MsgMerge should use PoMessage to generate PO content.

module GetText
  module Tools
    class MsgMerge
      class PoData  #:nodoc:

        attr_reader :msgids

        def initialize
          @msgid2msgstr = {}
          @msgid2comment = {}
          @msgids = []
        end

        def set_comment(msgid_or_sym, comment)
          @msgid2comment[msgid_or_sym] = comment
        end

        def msgstr(msgid)
          @msgid2msgstr[msgid]
        end

        def comment(msgid)
          @msgid2comment[msgid]
        end

        def [](msgid)
          @msgid2msgstr[msgid]
        end

        def []=(msgid, msgstr)
          # Retain the order
          if @msgid2msgstr[msgid].nil?
            @msgids << msgid
          end

          @msgid2msgstr[msgid] = msgstr
        end

        def each_msgid
          msgids = @msgids.delete_if do |msgid|
            msgid.kind_of?(Symbol) or msgid.empty?
          end

          msgids.each do |msgid|
            yield(msgid)
          end
        end

        def msgid?(msgid)
          return false if msgid.kind_of?(Symbol)
          return true if msgid.empty?
          @msgid2msgstr.has_key?(msgid)
        end

        # Is it necessary to implement this method?
        def search_msgid_fuzzy(msgid, used_msgids)
          nil
        end

        def nplurals
          return 0 if @msgid2msgstr[""].nil?

          if /\s*nplurals\s*=\s*(\d+)/ =~ @msgid2msgstr[""]
            return $1.to_i
          else
            return 0
          end
        end

        def generate_po
          str = ""
          str << generate_po_header

          po_entries = []
          self.each_msgid do |id|
            po_entries << self.generate_po_entry(id)
          end

          unless @msgid2comment[:last].empty?
            po_entries << "#{@msgid2comment[:last]}\n"
          end

          str << po_entries.join("\n")
          str
        end

        def generate_po_header
          str = ""

          str << @msgid2comment[""].strip << "\n"
          str << 'msgid ""'  << "\n"
          str << 'msgstr ""' << "\n"
          msgstr = @msgid2msgstr[""].gsub(/"/, '\"').gsub(/\r/, "")
          msgstr = msgstr.gsub(/^(.*)$/, '"\1\n"')
          str << msgstr
          str << "\n"

          str
        end

        def generate_po_entry(msgid)
          str = ""
          str << @msgid2comment[msgid]
          if str[-1] != "\n"[0]
            str << "\n"
          end

          id = msgid.gsub(/\r/, "")
          msgstr = @msgid2msgstr[msgid].gsub(/\r/, "")

          if id.include?("\004")
            ids = id.split(/\004/)
            context = ids[0]
            id      = ids[1]
            str << "msgctxt "  << __conv(context) << "\n"
          end

          if id.include?("\000")
            ids = id.split(/\000/)
            str << "msgid " << __conv(ids[0]) << "\n"
            ids[1..-1].each do |single_id|
              str << "msgid_plural " << __conv(single_id) << "\n"
            end

            msgstr.split("\000", -1).each_with_index do |m, n|
              str << "msgstr[#{n}] " << __conv(m) << "\n"
            end
          else
            str << "msgid "  << __conv(id) << "\n"
            str << "msgstr " << __conv(msgstr) << "\n"
          end

          str
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
          PoMessage.escape(string)
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

      bindtextdomain("rgettext")

      # constant values
      VERSION = GetText::VERSION

      def check_command_line_options(*options) #:nodoc:
        options, output = parse_arguments(*options)

        if output.nil?
          output = nil
        else
          if not FileTest.exist?(output)
            $stderr.puts(_("File '%s' has already existed.") % out)
            exit(false)
          end
        end

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

        parser.on("-h", "--help", _("Dispray this help and exit")) do
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

        parser = PoParser.new
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
