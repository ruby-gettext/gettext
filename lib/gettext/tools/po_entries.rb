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

      content_entries.each do |msgid, entry|
        po_entries << entry.to_s
      end

      po_entries.join("\n")
    end
  end
end
