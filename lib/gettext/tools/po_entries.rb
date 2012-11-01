# -*- coding: utf-8 -*-
#
# Copyright (C) 2012  Haruka Yoshihara <yoshihara@clear-code.com>
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

require "gettext/tools/po_entry"

module GetText
  class PoEntries < Hash
    def [](msgid)
      super(msgid)
    end

    def []=(msgid, msgstr)
      msgctxt, msgid, msgid_plural = split_msgid(msgid)

      if has_key?(msgid)
        entry = self[msgid]
      else
        type = detect_entry_type(msgctxt, msgid_plural)
        entry = PoEntry.new(type)
        super(msgid, entry)
      end
      entry.msgid = msgid
      entry.msgctxt = msgctxt
      entry.msgid_plural = msgid_plural
      entry.msgstr = msgstr
      entry
    end

    COMMENT_MARK = "#"
    SOURCE_COMMENT_MARK = "#:"
    def set_comment(msgid, comment)
      self[msgid] = nil unless has_key?(msgid)
      if comment.start_with?(SOURCE_COMMENT_MARK)
        sources = comment.lines.collect do |source|
          source.gsub(/\A#{Regexp.escape(SOURCE_COMMENT_MARK)}/, "").strip
        end
        self[msgid].sources = sources
      elsif comment.start_with?(COMMENT_MARK)
        comment_lines = ""
        comment.lines.each do |line|
          content = line.gsub(/\A#{Regexp.escape(COMMENT_MARK)}/, "").strip
          comment_lines << content << "\n"
        end
        self[msgid].comment = comment_lines
      else
        self[msgid].comment = comment
      end
    end

    def to_s
      po_string = ""

      header_entry = self[""]
      if header_entry.nil?
        content_entries = self
      else
        po_string << header_entry.to_s

        content_entries = reject do |msgid, _|
          msgid.empty?
        end
      end

      content_entries.each do |msgid, entry|
        po_string << entry.to_s
      end

      po_string
    end

    private
    def split_msgid(msgid)
      return [nil, "", nil] if msgid.empty?
      msgctxt, msgid = msgid.split("\004", 2)
      if msgid.nil?
        msgid = msgctxt
        msgctxt = nil
      end
      msgid, msgid_plural = msgid.split("\000", 2)
      [msgctxt, msgid, msgid_plural]
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
  end
end
