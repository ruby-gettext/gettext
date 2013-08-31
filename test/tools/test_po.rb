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

require "gettext/po"

class TestPO < Test::Unit::TestCase
  def setup
    @po = nil
  end

  class TestHasKey < self
    def setup
      @po = GetText::PO.new
    end

    def test_msgid_exist
      @po["msgid"] = "msgstr"

      assert_true(@po.has_key?("msgid"))
      assert_true(@po.has_key?(nil, "msgid"))
    end

    def test_msgid_notexistent
      assert_false(@po.has_key?("msgid"))
      assert_false(@po.has_key?(nil, "msgid"))
    end

    def test_msgctxt_and_msgid_exist
      @po["msgctxt", "msgid"] = "msgstr"

      assert_false(@po.has_key?("msgid"))
      assert_true(@po.has_key?("msgctxt", "msgid"))
    end

    def test_wrong_arguments
      @po["msgctxt", "msgid"] = "msgstr"

      assert_raise(ArgumentError) do
        @po.has_key?("msgctxt", "msgid", "wrong_argument")
      end
    end
  end

  class TestEach < self
    def setup
      @hello = "hello"
      @hello_translation = "bonjour"
      @he = "he"
      @he_translation = "il"

      @po = GetText::PO.new
      @po[@hello] = @hello_translation
      @po[@he] = @he_translation
    end

    def test_block_given
      entries = []
      @po.each do |entry|
        entries << entry
      end

      entries = entries.sort_by do |entry|
        entry.msgid
      end

      assert_equal(expected_entries, entries)
    end

    def test_no_block_given
      entries = @po.each.sort_by do |entry|
        entry.msgid
      end

      assert_equal(expected_entries, entries)
    end

    private
    def expected_entries
      he_entry = POEntry.new(:normal)
      he_entry.msgid = @he
      he_entry.msgstr = @he_translation
      hello_entry = POEntry.new(:normal)
      hello_entry.msgid = @hello
      hello_entry.msgstr = @hello_translation

      [he_entry, hello_entry]
    end
  end

  class TestSetEntry < self
    def test_normal
      msgid = "msgid"
      msgstr = "msgstr"

      @po = GetText::PO.new
      @po[msgid] = msgstr

      entry = POEntry.new(:normal)
      entry.msgid = msgid
      entry.msgstr = msgstr
      assert_equal(entry, @po[msgid])
    end

    def test_msgctxt
      msgctxt = "msgctxt"
      msgid = "msgid"
      msgstr = "msgstr"

      @po = GetText::PO.new
      @po[msgctxt, msgid] = msgstr

      entry = POEntry.new(:msgctxt)
      entry.msgctxt = msgctxt
      entry.msgid = msgid
      entry.msgstr = msgstr
      assert_equal(entry, @po[msgctxt, msgid])
    end

    def test_wrong_arguments
      msgctxt = "msgctxt"
      msgid = "msgid"
      msgstr = "msgstr"

      @po = GetText::PO.new
      assert_raise(ArgumentError) do
        @po[msgctxt, msgid, "wrong argument"] = msgstr
      end
    end

    def test_update_existing_entry
      test_normal

      msgid = "msgid"
      new_msgstr = "new_msgstr"
      @po[msgid] = new_msgstr

      entry = POEntry.new(:normal)
      entry.msgid = msgid
      entry.msgstr = new_msgstr
      assert_equal(entry, @po[msgid])
    end

    def test_po_entry
      @po = GetText::PO.new

      msgid = "msgid"
      msgstr = "msgstr"
      entry = POEntry.new(:normal)
      entry.msgid = msgid
      entry.msgstr = msgstr

      @po[msgid] = entry
      assert_true(@po.has_key?(nil, msgid))
      assert_equal(msgstr, @po[msgid].msgstr)
    end
  end

  class TestComment < self
    def test_add
      msgid = "msgid"
      comment = "comment"

      @po = GetText::PO.new
      @po.set_comment(msgid, comment)

      entry = POEntry.new(:normal)
      entry.msgid = msgid
      entry.comment = comment
      assert_equal(entry, @po[msgid])
      assert_equal(nil, @po[msgid].msgstr)
    end

    def test_add_to_existing_entry
      msgid = "msgid"
      msgstr = "msgstr"
      @po = GetText::PO.new
      @po[msgid] = msgstr

      comment = "comment"
      @po.set_comment(msgid, comment)

      entry = POEntry.new(:normal)
      entry.msgid = msgid
      entry.msgstr = msgstr
      entry.comment = comment
      assert_equal(entry, @po[msgid])
    end
  end

  class TestToS < self
    def setup
      @po = GetText::PO.new
      @po[""] = header
      @po[""].translator_comment = header_comment
    end

    def test_same_filename
      hello = "hello"
      hello_translation = "こんにちは"
      hello_references = ["file.rb:10"]
      hello_comment = "#: file.rb:10"
      bye = "bye"
      bye_translation = "さようなら"
      bye_references = ["file.rb:20"]
      bye_comment = "#: file.rb:20"

      @po[hello] = hello_translation
      @po[hello].references = hello_references

      @po[bye] = bye_translation
      @po[bye].references = bye_references

      expected_po =<<EOP
#{expected_header_comment}
#
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
      assert_equal(expected_po, @po.to_s)
    end

    def test_different_filename
      hello = "hello"
      hello_translation = "こんにちは"
      hello_references = ["file.rb:10"]
      hello_comment = "#: file.rb:10"
      bye = "bye"
      bye_translation = "さようなら"
      bye_references = ["test.rb:10"]
      bye_comment = "#: test.rb:10"

      @po[hello] = hello_translation
      @po[hello].references = hello_references

      @po[bye] = bye_translation
      @po[bye].references = bye_references

      expected_po =<<EOP
#{expected_header_comment}
#
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
      assert_equal(expected_po, @po.to_s)
    end

    def test_including_colon_filename
      hello = "hello"
      hello_translation = "こんにちは"
      hello_references = ["file.rb:10"]
      hello_comment = "#: file.rb:10"
      bye = "bye"
      bye_translation = "さようなら"
      bye_references = ["file:2.rb:10"]
      bye_comment = "#: file:2.rb:10"

      @po[hello] = hello_translation
      @po[hello].references = hello_references

      @po[bye] = bye_translation
      @po[bye].references = bye_references

      expected_po =<<EOP
#{expected_header_comment}
#
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
      assert_equal(expected_po, @po.to_s)
    end

    def test_no_file_number
      hello = "hello"
      hello_translation = "こんにちは"
      hello_references = ["file.rb"]
      hello_comment = "#: file.rb"
      bye = "bye"
      bye_translation = "さようなら"
      bye_references = ["test.rb"]
      bye_comment = "#: test.rb"

      @po[hello] = hello_translation
      @po[hello].references = hello_references

      @po[bye] = bye_translation
      @po[bye].references = bye_references

      expected_po =<<EOP
#{expected_header_comment}
#
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
      assert_equal(expected_po, @po.to_s)
    end

    def test_multiple_filename
      hello = "hello"
      hello_translation = "こんにちは"
      hello_references = ["file.rb:10"]
      hello_comment = "#: file.rb:10"
      bye = "bye"
      bye_translation = "さようなら"
      bye_references = ["test.rb:10", "file.rb:110", "file.rb:20"]
      bye_comment = "#: file.rb:20 file.rb:110 test.rb:10"

      @po[hello] = hello_translation
      @po[hello].references = hello_references

      @po[bye] = bye_translation
      @po[bye].references = bye_references

      expected_po =<<EOP
#{expected_header_comment}
#
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
      assert_equal(expected_po, @po.to_s)
    end

    def test_obsolete_comment
      hello = "hello"
      hello_translation = "こんにちは"
      hello_references = ["file.rb:10"]

      @po[hello] = hello_translation
      @po[hello].references = hello_references

      @po.set_comment(:last, obsolete_comment)

      hello_comment = "#: file.rb:10"
      expected_po =<<EOP
#{expected_header_comment}
#
msgid ""
msgstr ""
#{expected_header}

#{hello_comment}
msgid "#{hello}"
msgstr "#{hello_translation}"

#{expected_obsolete_comment}
EOP
      assert_equal(expected_po, @po.to_s)
    end

    def test_obsolete_comment_without_header
      @po = GetText::PO.new

      hello = "hello"
      hello_translation = "こんにちは"
      hello_references = ["file.rb:10"]

      @po[hello] = hello_translation
      @po[hello].references = hello_references

      @po.set_comment(:last, obsolete_comment)

      hello_comment = "#: file.rb:10"
      expected_po =<<EOP

#{hello_comment}
msgid "#{hello}"
msgstr "#{hello_translation}"

#{expected_obsolete_comment}
EOP
      assert_equal(expected_po, @po.to_s)
    end

    private
    def header
      <<EOH
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
    end

    def header_comment
      <<EOC
Japanese translations for test package.
Copyright (C) 2012 THE PACKAGE'S COPYRIGHT HOLDER
This file is distributed under the same license as the PACKAGE package.
FULLNAME <MAIL@ADDRESS>, 2012.

EOC
    end

    def expected_header
      expected_header = header.split("\n").collect do |line|
        "\"#{line}\\n\""
      end
      expected_header.join("\n")
    end

    def expected_header_comment
      expected_header_comment = header_comment.split("\n").collect do |line|
        "# #{line}"
      end
      expected_header_comment.join("\n")
    end

    def obsolete_comment
      <<EOC
# test.rb:10
msgid \"hello\"
msgstr \"Salut\"

# test.rb:20
msgid \"hi\"
msgstr \"Bonjour\"
EOC
    end

    def expected_obsolete_comment
      comment = <<EOC
# test.rb:10
#~ msgid \"hello\"
#~ msgstr \"Salut\"

# test.rb:20
#~ msgid \"hi\"
#~ msgstr \"Bonjour\"
EOC
      comment.chomp
    end
  end
end
