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
  class PO < Hash
    class NonExistentEntryError < StandardError
    end

    attr_accessor :order
    def initialize(order=nil)
      @order = order || :references
    end

    def [](msgid)
      super(msgid)
    end

    def []=(msgid, value)
      if value.instance_of?(PoEntry)
        super(msgid, value)
        return(value)
      end

      msgstr = value
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

    def set_references(msgid, references)
      unless has_key?(msgid)
        raise(NonExistentEntryError,
              "the entry of \"%s\" does not exist." % msgid)
      end
      self[msgid].references = references
    end

    def to_s
      po_string = ""

      header_entry = self[""]
      if header_entry.nil?
        content_entries = self
      else
        po_string << header_entry.to_s

        content_entries = reject do |msgid, _|
          msgid.empty? or msgid == :last
        end
      end

      sort_by_order(content_entries).each do |msgid, entry|
        po_string << "\n" << entry.to_s
      end

      po_string << self[:last].to_s if has_key?(:last)

      po_string
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
      entries.each do |_, entry|
        entry.references = entry.references.sort do |reference, other|
          compare_references(reference, other)
        end
      end

      entries.sort do |msgid_entry, other_msgid_entry|
        # msgid_entry = [msgid, PoEntry]
        entry_first_reference = msgid_entry[1].references.first
        other_first_reference = other_msgid_entry[1].references.first
        compare_references(entry_first_reference, other_first_reference)
      end
    end

    def compare_references(reference, other)
      entry_source, entry_line_number = split_reference(reference)
      other_source, other_line_number = split_reference(other)

      if entry_source != other_source
        entry_source <=> other_source
      else
        entry_line_number <=> other_line_number
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
