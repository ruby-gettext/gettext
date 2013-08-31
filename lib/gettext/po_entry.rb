# -*- coding: utf-8 -*-
#
# Copyright (C) 2012  Kouhei Sutou <kou@clear-code.com>
# Copyright (C) 2010  masone (Christian Felder) <ema@rh-productions.ch>
# Copyright (C) 2009  Masao Mutoh
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

module GetText
  class ParseError < StandardError
  end

  # Contains data related to the expression or sentence that
  # is to be translated.
  class POEntry
    class InvalidTypeError < StandardError
    end

    class NoMsgidError < StandardError
    end

    class NoMsgctxtError < StandardError
    end

    class NoMsgidPluralError < StandardError
    end

    PARAMS = {
      :normal => [:msgid, :separator, :msgstr],
      :plural => [:msgid, :msgid_plural, :separator, :msgstr],
      :msgctxt => [:msgctxt, :msgid, :msgstr],
      :msgctxt_plural => [:msgctxt, :msgid, :msgid_plural, :msgstr]
    }

   TRANSLATOR_COMMENT_MARK = "# "
   EXTRACTED_COMMENT_MARK = "#."
   FLAG_MARK = "#,"
   PREVIOUS_COMMENT_MARK = "#|"
   REFERENCE_COMMENT_MARK = "#:"

    class << self
      def escape(string)
        string.gsub(/([\\"\t\n])/) do
          special_character = $1
          case special_character
          when "\t"
            "\\t"
          when "\n"
            "\\n"
          else
            "\\#{special_character}"
          end
        end
      end
    end

    @@max_line_length = 70

    # Sets the max line length.
    def self.max_line_length=(len)
      @@max_line_length = len
    end

    # Gets the max line length.
    def self.max_line_length
      @@max_line_length
    end

    # Required
    attr_reader :type          # :normal, :plural, :msgctxt, :msgctxt_plural
    attr_accessor :msgid
    attr_accessor :msgstr
    # Options
    attr_accessor :msgid_plural
    attr_accessor :separator
    attr_accessor :msgctxt
    attr_accessor :references    # ["file1:line1", "file2:line2", ...]
    attr_accessor :translator_comment
    attr_accessor :extracted_comment
    attr_accessor :flag
    attr_accessor :previous
    attr_accessor :comment

    # Create the object. +type+ should be :normal, :plural, :msgctxt or :msgctxt_plural.
    def initialize(type)
      self.type = type
      @translator_comment = nil
      @extracted_comment = nil
      @references = []
      @flag = nil
      @previous = nil
      @msgctxt = nil
      @msgid = nil
      @msgid_plural = nil
      @msgstr = nil
    end

    # Support for extracted comments. Explanation s.
    # http://www.gnu.org/software/gettext/manual/gettext.html#Names
    def add_comment(new_comment)
      if (new_comment and ! new_comment.empty?)
        @extracted_comment ||= ""
        @extracted_comment << "\n" unless @extracted_comment.empty?
        @extracted_comment << new_comment
      end
      to_s
    end

    # Returns a parameter representation suitable for po-files
    # and other purposes.
    def escaped(param_name)
      escape(send(param_name))
    end

    # Checks if the self has same attributes as other.
    def ==(other)
      not other.nil? and
        type == other.type and
        msgid == other.msgid and
        msgstr == other.msgstr and
        msgid_plural == other.msgid_plural and
        separator == other.separator and
        msgctxt == other.msgctxt and
        translator_comment == other.translator_comment and
        extracted_comment == other.extracted_comment and
        references == other.references and
        flag == other.flag and
        previous == other.previous and
        comment == other.comment
    end

    def type=(type)
      unless PARAMS.has_key?(type)
        raise(InvalidTypeError, "\"%s\" is invalid type." % type)
      end
      @type = type
      @param_type = PARAMS[@type]
    end

    # Checks if the other translation target is mergeable with
    # the current one. Relevant are msgid and translation context (msgctxt).
    def mergeable?(other)
      other && other.msgid == self.msgid && other.msgctxt == self.msgctxt
    end

    # Merges two translation targets with the same msgid and returns the merged
    # result. If one is declared as plural and the other not, then the one
    # with the plural wins.
    def merge(other)
      return self unless other
      raise ParseError, "Translation targets do not match: \n" \
      "  self: #{self.inspect}\n  other: '#{other.inspect}'" unless self.mergeable?(other)
      if other.msgid_plural && !self.msgid_plural
        res = other
        unless (res.references.include? self.references[0])
          res.references += self.references
          res.add_comment(self.extracted_comment)
        end
      else
        res = self
        unless (res.references.include? other.references[0])
          res.references += other.references
          res.add_comment(other.extracted_comment)
        end
      end
      res
    end

    # Output the po entry for the po-file.
    def to_s
      raise(NoMsgidError, "msgid is nil.") unless @msgid

      str = ""
      # extracted comments
      if @msgid == :last
        return format_obsolete_comment(comment)
      end

      str << format_translator_comment
      str << format_extracted_comment
      str << format_reference_comment
      str << format_flag_comment
      str << format_previous_comment

      # msgctxt, msgid, msgstr
      if msgctxt?
        if @msgctxt.nil?
          no_msgctxt_message = "This POEntry is a kind of msgctxt " +
                                 "but the msgctxt property is nil. " +
                                 "msgid: #{msgid}"
          raise(NoMsgctxtError, no_msgctxt_message)
        end
        str << "msgctxt " << format_message(msgctxt)
      end

      str << "msgid " << format_message(msgid)
      if plural?
        if @msgid_plural.nil?
          no_plural_message = "This POEntry is a kind of plural " +
                                "but the msgid_plural property is nil. " +
                                "msgid: #{msgid}"
          raise(NoMsgidPluralError, no_plural_message)
        end

        str << "msgid_plural " << format_message(msgid_plural)

        if msgstr.nil?
          str << "msgstr[0] \"\"\n"
          str << "msgstr[1] \"\"\n"
        else
          msgstrs = msgstr.split("\000", -1)
          msgstrs.each_with_index do |msgstr, index|
            str << "msgstr[#{index}] " << format_message(msgstr)
          end
        end
      else
        str << "msgstr "
        str << format_message(msgstr)
      end
      str
    end

    def format_translator_comment
      format_comment("#", translator_comment)
    end

    def format_extracted_comment
      format_comment(EXTRACTED_COMMENT_MARK, extracted_comment)
    end

    def format_reference_comment
      max_line_length = 70
      formatted_reference = ""
      if not references.nil? and not references.empty?
        formatted_reference << REFERENCE_COMMENT_MARK
        line_size = 2
        references.each do |reference|
          if line_size + reference.size > max_line_length
            formatted_reference << "\n"
            formatted_reference <<  "#{REFERENCE_COMMENT_MARK} #{reference}"
            line_size = 3 + reference.size
          else
            formatted_reference << " #{reference}"
            line_size += 1 + reference.size
          end
        end

        formatted_reference << "\n"
      end
      formatted_reference
    end

    def format_flag_comment
      format_comment(FLAG_MARK, flag)
    end

    def format_previous_comment
      format_comment(PREVIOUS_COMMENT_MARK, previous)
    end

    def format_comment(mark, comment)
      return "" if comment.nil?

      formatted_comment = ""
      comment.each_line do |comment_line|
        if comment_line == "\n"
          formatted_comment << "#{mark}\n"
        else
          formatted_comment << "#{mark} #{comment_line.strip}\n"
        end
      end
      formatted_comment
    end

    def format_obsolete_comment(comment)
      mark = "#~"
      return "" if comment.nil?

      formatted_comment = ""
      comment.each_line do |comment_line|
        if /\A#[^~]/ =~ comment_line or comment_line.start_with?(mark)
          formatted_comment << comment_line
        elsif comment_line == "\n"
          formatted_comment << "\n"
        else
          formatted_comment << "#{mark} #{comment_line.strip}\n"
        end
      end
      formatted_comment
    end

    def format_message(message)
      formatted_message = ""
      if not message.nil? and message.include?("\n")
        formatted_message << "\"\"\n"
        message.each_line.each do |line|
          formatted_message << "\"#{escape(line)}\"\n"
        end
      else
        formatted_message << "\"#{escape(message)}\"\n"
      end
      formatted_message
    end

    # Returns true if the type is kind of msgctxt.
    def msgctxt?
      [:msgctxt, :msgctxt_plural].include?(@type)
    end

    # Returns true if the type is kind of plural.
    def plural?
      [:plural, :msgctxt_plural].include?(@type)
    end

    private

    # sets or extends the value of a translation target params like msgid,
    # msgctxt etc.
    #   param is symbol with the name of param
    #   value - new value
    def set_value(param, value)
      send "#{param}=", (send(param) || '') + value
    end

    def escape(value)
      self.class.escape((value || "").gsub(/\r/, ""))
    end

    public
    # For backward comatibility. This doesn't support "comment".
    # ary = [msgid1, "file1:line1", "file2:line"]
    def self.new_from_ary(ary)
      ary = ary.dup
      msgid = ary.shift
      references = ary
      type = :normal
      msgctxt = nil
      msgid_plural = nil

      if msgid.include? "\004"
        msgctxt, msgid = msgid.split(/\004/)
        type = :msgctxt
      end
      if msgid.include? "\000"
        ids = msgid.split(/\000/)
        msgid = ids[0]
        msgid_plural = ids[1]
        if type == :msgctxt
          type = :msgctxt_plural
        else
          type = :plural
        end
      end
      ret = self.new(type)
      ret.msgid = msgid
      ret.references = references
      ret.msgctxt = msgctxt
      ret.msgid_plural = msgid_plural
      ret
    end

    def [](number)
      param = @param_type[number]
      raise ParseError, 'no more string parameters expected' unless param
      send param
    end
  end

end
