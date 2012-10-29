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

require "gettext/tools/po_entries"

class TestPoEntries < Test::Unit::TestCase
  def setup
    @entries = nil
  end

  def test_add_new_entry
    msgid = "msgid"
    msgstr = "msgstr"

    @entries = GetText::PoEntries.new
    @entries[msgid] = msgstr

    entry = PoEntry.new(:normal)
    entry.msgid = msgid
    entry.msgstr = msgstr
    assert_equal(entry, @entries[msgid])
  end

  def test_update_existed_entry
    test_add_new_entry

    msgid = "msgid"
    new_msgstr = "new_msgstr"
    @entries[msgid] = new_msgstr

    entry = PoEntry.new(:normal)
    entry.msgid = msgid
    entry.msgstr = new_msgstr
    assert_equal(entry, @entries[msgid])
  end

  def test_add_comment
    msgid = "msgid"
    comment = "comment"

    @entries = GetText::PoEntries.new
    @entries.set_comment(msgid, comment)

    entry = PoEntry.new(:normal)
    entry.msgid = msgid
    entry.comment = comment
    assert_equal(entry, @entries[msgid])
  end

  def test_add_comment_to_existing_entry
    test_add_new_entry

    msgid = "msgid"
    msgstr = "msgstr"
    comment = "comment"

    @entries[msgid] = msgstr

    entry = PoEntry.new(:normal)
    entry.msgid = msgid
    entry.msgstr = msgstr
    entry.comment = comment
    assert_equal(entry, @entries[msgid])
  end
end
