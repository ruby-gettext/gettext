# -*- coding: utf-8 -*-
#
# Copyright (C) 2012  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2012  Kouhei Sutou <kou@clear-code.com>
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

  class TestSetEntry < self
    def test_normal
      msgid = "msgid"
      msgstr = "msgstr"

      @entries = GetText::PoEntries.new
      @entries[msgid] = msgstr

      entry = PoEntry.new(:normal)
      entry.msgid = msgid
      entry.msgstr = msgstr
      assert_equal(entry, @entries[msgid])
    end

    def test_msgctxt
      msgctxt = "msgctxt"
      msgid = "msgid"
      msgstr = "msgstr"

      @entries = GetText::PoEntries.new
      @entries["#{msgctxt}\004#{msgid}"] = msgstr

      entry = PoEntry.new(:msgctxt)
      entry.msgctxt = msgctxt
      entry.msgid = msgid
      entry.msgstr = msgstr
      assert_equal(entry, @entries[msgid])
    end

    def test_msgid_plural
      msgid = "msgid"
      msgid_plural = "msgid_plural"
      msgstr = "msgstr"

      @entries = GetText::PoEntries.new
      @entries["#{msgid}\000#{msgid_plural}"] = msgstr

      entry = PoEntry.new(:plural)
      entry.msgid = msgid
      entry.msgid_plural = msgid_plural
      entry.msgstr = msgstr
      assert_equal(entry, @entries[msgid])
    end

    def test_msgctxt_plural
      msgctxt = "msgctxt"
      msgid = "msgid"
      msgid_plural = "msgid_plural"
      msgstr = "msgstr"

      @entries = GetText::PoEntries.new
      @entries["#{msgctxt}\004#{msgid}\000#{msgid_plural}"] = msgstr

      entry = PoEntry.new(:msgctxt_plural)
      entry.msgctxt = msgctxt
      entry.msgid = msgid
      entry.msgid_plural = msgid_plural
      entry.msgstr = msgstr
      assert_equal(entry, @entries[msgid])
    end

    def test_update_existed_entry
      test_normal

      msgid = "msgid"
      new_msgstr = "new_msgstr"
      @entries[msgid] = new_msgstr

      entry = PoEntry.new(:normal)
      entry.msgid = msgid
      entry.msgstr = new_msgstr
      assert_equal(entry, @entries[msgid])
    end
  end

  class TestComment < self
    def test_add
      msgid = "msgid"
      comment = "comment"

      @entries = GetText::PoEntries.new
      @entries.set_comment(msgid, comment)

      entry = PoEntry.new(:normal)
      entry.msgid = msgid
      entry.comment = comment
      assert_equal(entry, @entries[msgid])
      assert_equal(nil, @entries[msgid].msgstr)
    end

    def test_add_to_existing_entry
      msgid = "msgid"
      msgstr = "msgstr"
      @entries = GetText::PoEntries.new
      @entries[msgid] = msgstr

      comment = "comment"
      @entries.set_comment(msgid, comment)

      entry = PoEntry.new(:normal)
      entry.msgid = msgid
      entry.msgstr = msgstr
      entry.comment = comment
      assert_equal(entry, @entries[msgid])
    end
  end

  class TestSources < self
    def test_add
      msgid = "msgid"
      sources = ["comment:10", "comment: 12"]
      source_comments = sources.collect do |source|
        "#: #{source}"
      end
      comment = source_comments.join("\n")

      @entries = GetText::PoEntries.new
      @entries.set_comment(msgid, comment)

      entry = PoEntry.new(:normal)
      entry.msgid = msgid
      entry.sources = sources
      assert_equal(entry, @entries[msgid])
      assert_equal(sources, @entries[msgid].sources)
    end

    def test_mark_in_source
      msgid = "msgid"
      sources = ["dir/\#: /file:10", "comment:12"]
      source_comments = sources.collect do |source|
        "#: #{source}"
      end
      comment = source_comments.join("\n")

      @entries = GetText::PoEntries.new
      @entries.set_comment(msgid, comment)

      entry = PoEntry.new(:normal)
      entry.msgid = msgid
      entry.sources = sources
      assert_equal(entry, @entries[msgid])
      assert_equal(sources, @entries[msgid].sources)
    end
  end

  class TestSplitMsgid < self
    def test_existed_msgctxt_and_msgid_plural
      msgctxt = "msgctxt"
      msgid = "msgid"
      msgid_plural = "msgid_plural"

      assert_equal([msgctxt, msgid, msgid_plural],
                   split_msgid("#{msgctxt}\004#{msgid}\000#{msgid_plural}"))
    end

    def test_existed_msgctxt_only
      msgctxt = "msgctxt"
      msgid = "msgid"

      assert_equal([msgctxt, msgid, nil],
                   split_msgid("#{msgctxt}\004#{msgid}"))
    end

    def test_existed_msgid_plural_only
      msgid = "msgid"
      msgid_plural = "msgid_plural"

      assert_equal([nil, msgid, msgid_plural],
                   split_msgid("#{msgid}\000#{msgid_plural}"))
    end

    def test_not_existed
      msgid = "msgid"

      assert_equal([nil, msgid, nil], split_msgid(msgid))
    end

    def test_empty_msgid
      msgid = ""

      assert_equal([nil, msgid, nil], split_msgid(msgid))
    end

    private
    def split_msgid(msgid)
      entries = GetText::PoEntries.new
      entries.send(:split_msgid, msgid)
    end
  end

  def test_to_s
    @entries = GetText::PoEntries.new
    header = <<EOH
Project-Id-Version: test 1.0.0
POT-Creation-Date: 2012-10-31 12:40+0900
PO-Revision-Date: 2012-11-01 17:46+0900
Last-Translator: FULLNAME <MAIL@ADDRESS>
Language-Team: Japanese
Language: 
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
Plural-Forms: nplurals=2; plural=(n != 1)
EOH
    header_comment = <<EOC
# Japanese translations for test package.
# Copyright (C) 2012 THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# FULLNAME <MAIL@ADDRESS>, 2012.
#
EOC
    hello = "hello"
    hello_translation = "こんにちは"
    hello_comment = "#: file.rb:10"
    bye = "bye"
    bye_translation = "さようなら"
    bye_comment = "#: file.rb:20"

    @entries[""] = header
    @entries.set_comment("", header_comment)

    @entries[hello] = hello_translation
    @entries.set_comment(hello, hello_comment)

    @entries[bye] = bye_translation
    @entries.set_comment(bye, bye_comment)

    expected_header = header.split("\n").collect do |line|
      "\"#{line}\\n\""
    end
    expected_header = expected_header.join("\n")

    expected_po =<<EOP
#{header_comment.chomp}
msgid ""
msgstr ""
#{expected_header}

#{hello_comment}
msgid "#{hello}"
msgstr "#{hello_translation}"

#{bye_comment}
msgid "#{bye}"
msgstr "#{bye_translation}"
EOP
    assert_equal(expected_po, @entries.to_s)
  end
end
