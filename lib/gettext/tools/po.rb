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
  class PO
    include Enumerable

    class NonExistentEntryError < StandardError
    end

    attr_accessor :order
    def initialize(order=nil)
      @order = order || :references
      @entries = {}
    end

    def [](msgctxt, msgid=nil)
      if msgid.nil?
        msgid = msgctxt
        msgctxt = nil
      end

      @entries[[msgctxt, msgid]]
    end

    def []=(*arguments)
      case arguments.size
      when 2
        msgctxt = nil
        msgid = arguments[0]
        value = arguments[1]
      when 3
        msgctxt = arguments[0]
        msgid = arguments[1]
        value = arguments[2]
      else
        raise(ArgumentError,
              "[]=: wrong number of arguments(#{arguments.size} for 2..3)")
      end

      id = [msgctxt, msgid]
      if value.instance_of?(POEntry)
        @entries[id] = value
        return(value)
      end

      msgstr = value
      if @entries.has_key?(id)
        entry = @entries[id]
      else
        if msgctxt.nil?
          entry = POEntry.new(:normal)
        else
          entry = POEntry.new(:msgctxt)
        end
        @entries[id] = entry
      end
      entry.msgctxt = msgctxt
      entry.msgid = msgid
      entry.msgstr = msgstr
      entry
    end

    def has_key?(*arguments)
      case arguments.size
      when 1
        msgctxt = nil
        msgid = arguments[0]
      when 2
        msgctxt = arguments[0]
        msgid = arguments[1]
      else
        message = "has_key?: wrong number of arguments " +
                    "(#{arguments.size} for 1..2)"
        raise(ArgumentError, message)
      end
      id = [msgctxt, msgid]
      @entries.has_key?(id)
    end

    def each
      if block_given?
        @entries.each do |_, entry|
          yield(entry)
        end
      else
        @entries.each_value
      end
    end

    def set_comment(msgid, comment, msgctxt=nil)
      id = [msgctxt, msgid]
      self[*id] = nil unless @entries.has_key?(id)
      self[*id].comment = comment
    end

    def set_references(msgid, references, msgctxt=nil)
      id = [msgctxt, msgid]
      unless @entries.has_key?(id)
        raise(NonExistentEntryError,
              "the entry of \"%s\" does not exist." % msgid)
      end
      self[*id].references = references
    end

    def to_s
      po_string = ""

      header_entry = @entries[[nil, ""]]
      po_string << header_entry.to_s unless header_entry.nil?

      content_entries = @entries.reject do |(msgctxt, msgid), _|
        msgid == :last or msgid.empty?
      end

      sort_by_order(content_entries).each do |msgid, entry|
        po_string << "\n" << entry.to_s
      end

      if @entries.has_key?([nil, :last])
        po_string << "\n" << @entries[[nil, :last]].to_s
      end

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
        # msgid_entry = [[msgctxt, msgid], POEntry]
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
      return ["", -1] if reference.nil?
      if /\A(.+):(\d+?)\z/ =~ reference
        [$1, $2.to_i]
      else
        [reference, -1]
      end
    end
  end
end
