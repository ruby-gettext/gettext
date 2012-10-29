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
      msgid, msgid_plural = msgid.split("\000", 2)
      if has_key?(msgid)
        entry = self[msgid]
      else
        if msgid_plural.nil?
          type = :normal
        else
          type = :plural
        end
        entry = PoEntry.new(type)
        super(msgid, entry)
      end
      entry.msgid = msgid
      entry.msgid_plural = msgid_plural
      entry.msgstr = msgstr
      entry
    end

    def set_comment(msgid, comment)
      self[msgid] = nil unless has_key?(msgid)
      self[msgid].comment = comment
    end
  end
end
