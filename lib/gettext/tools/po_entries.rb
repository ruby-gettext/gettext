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
    class NonExistentEntryError < StandardError
    end

    attr_accessor :order
    def initialize(order=nil)
      @order = order || :references
    end

    def [](msgid)
      super(msgid)
    end

    def []=(msgid, msgstr)
      if has_key?(msgid)
        entry = self[msgid]
      else
        entry = PoEntry.new(:normal)
        super(msgid, entry)
      end
      entry.msgid = msgid
      entry.msgstr = msgstr
      entry
    end

    def set_type(msgid, type)
      unless has_key?(msgid)
        raise(NonExistentEntryError,
              "the entry of \"%s\" does not exist." % msgid)
      end
      self[msgid].type = type
    end

    def set_comment(msgid, comment)
      self[msgid] = nil unless has_key?(msgid)
      self[msgid].comment = comment
    end

    def set_msgctxt(msgid, msgctxt)
      unless has_key?(msgid)
        raise(NonExistentEntryError,
              "the entry of \"%s\" does not exist." % msgid)
      end
      self[msgid].msgctxt = msgctxt
    end

    def set_msgid_plural(msgid, msgid_plural)
      unless has_key?(msgid)
        raise(NonExistentEntryError,
              "the entry of \"%s\" does not exist." % msgid)
      end
      self[msgid].msgid_plural = msgid_plural
    end

    def set_sources(msgid, sources)
      unless has_key?(msgid)
        raise(NonExistentEntryError,
              "the entry of \"%s\" does not exist." % msgid)
      end
      self[msgid].sources = sources
    end

    def to_s
      po_entries = []

      header_entry = self[""]
      if header_entry.nil?
        content_entries = self
      else
        po_entries << header_entry.to_s

        content_entries = reject do |msgid, _|
          msgid.empty?
        end
      end

      sort_by_order(content_entries).each do |entry|
        po_entries << entry[1].to_s
      end

      po_entries.join("\n")
    end

    private
    def sort_by_order(entries)
      case @order
      when :references
        sorted_entries = sort_by_references(entries)
      when :msgid
        # TODO: sort by msgid alphabetically.
      else
        sorted_entries = entries.to_a
      end
    end

    def sort_by_references(entries)
      entries.each do |msgid, entry|
         #TODO: sort by each filename and line_number.
        entry.sources = entry.sources.sort
      end

      entries.sort do |entry, other|
        entry_sources = entry[1].sources
        entry_source, entry_line_number = split_reference(entry_sources.first)
        other_sources = other[1].sources
        other_source, other_line_number = split_reference(other_sources.first)

        if entry_source != other_source
          entry_source <=> other_source
        else
          entry_line_number <=> other_line_number
        end
      end
    end

    def split_reference(reference)
      if /\A(.+):(\d+?)\z/ =~ reference
        [$1, $2.to_i]
      else
        [reference, nil]
      end
    end
  end
end
