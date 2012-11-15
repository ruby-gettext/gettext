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

require "gettext/tools/po"

class TestPO < Test::Unit::TestCase
  def setup
    @entries = nil
  end

  class TestSetEntry < self
    def test_normal
      msgid = "msgid"
      msgstr = "msgstr"

      @entries = GetText::PO.new
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

      @entries = GetText::PO.new
      @entries[msgctxt, msgid] = msgstr

      entry = PoEntry.new(:msgctxt)
      entry.msgctxt = msgctxt
      entry.msgid = msgid
      entry.msgstr = msgstr
      assert_equal(entry, @entries[msgctxt, msgid])
    end

    def test_wrong_arguments
      msgctxt = "msgctxt"
      msgid = "msgid"
      msgstr = "msgstr"

      @entries = GetText::PO.new
      assert_raise(ArgumentError) do
        @entries[msgctxt, msgid, "wrong argument"] = msgstr
      end
    end

    def test_update_existing_entry
      test_normal

      msgid = "msgid"
      new_msgstr = "new_msgstr"
      @entries[msgid] = new_msgstr

      entry = PoEntry.new(:normal)
      entry.msgid = msgid
      entry.msgstr = new_msgstr
      assert_equal(entry, @entries[msgid])
    end

    def test_po_entry
      @entries = GetText::PO.new

      msgid = "msgid"
      msgstr = "msgstr"
      entry = PoEntry.new(:normal)
      entry.msgid = msgid
      entry.msgstr = msgstr

      @entries[msgid] = entry
      assert_true(@entries.has_key?([nil, msgid]))
      assert_equal(msgstr, @entries[msgid].msgstr)
    end
  end

  class TestComment < self
    def test_add
      msgid = "msgid"
      comment = "comment"

      @entries = GetText::PO.new
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
      @entries = GetText::PO.new
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

  class TestSetReferences < self
    def test_add
      msgid = "msgid"
      msgstr = "msgstr"
      references = ["file.rb:10"]

      @entries = GetText::PO.new
      @entries[msgid] = msgstr
      @entries.set_references(msgid, references)

      assert_equal(references, @entries[msgid].references)
    end

    def test_add_to_non_existent_entry
      msgid = "msgid"
      references = ["file.rb:10"]

      @entries = GetText::PO.new
      assert_raise(GetText::PO::NonExistentEntryError) do
        @entries.set_references(msgid, references)
      end
    end
  end

  class TestToS < self
    def setup
      @entries = GetText::PO.new
      @entries[""] = header
      @entries.set_comment("", header_comment)
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

      @entries[hello] = hello_translation
      @entries[hello].references = hello_references

      @entries[bye] = bye_translation
      @entries[bye].references = bye_references

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
      assert_equal(expected_po, @entries.to_s)
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

      @entries[hello] = hello_translation
      @entries[hello].references = hello_references

      @entries[bye] = bye_translation
      @entries[bye].references = bye_references

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
      assert_equal(expected_po, @entries.to_s)
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

      @entries[hello] = hello_translation
      @entries[hello].references = hello_references

      @entries[bye] = bye_translation
      @entries[bye].references = bye_references

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
      assert_equal(expected_po, @entries.to_s)
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

      @entries[hello] = hello_translation
      @entries[hello].references = hello_references

      @entries[bye] = bye_translation
      @entries[bye].references = bye_references

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
      assert_equal(expected_po, @entries.to_s)
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

      @entries[hello] = hello_translation
      @entries[hello].references = hello_references

      @entries[bye] = bye_translation
      @entries[bye].references = bye_references

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
      assert_equal(expected_po, @entries.to_s)
    end

    def test_obsolete_comment
      hello = "hello"
      hello_translation = "こんにちは"
      hello_references = ["file.rb:10"]

      @entries[hello] = hello_translation
      @entries[hello].references = hello_references

      obsolete_comment =<<EOC
# test.rb:10
msgid \"hello\"
msgstr \"Salut\"
EOC
      @entries.set_comment(:last, obsolete_comment)

      hello_comment = "#: file.rb:10"
      expected_obsolete_comment = obsolete_comment.gsub(/^/, "#~ ").chomp
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
      assert_equal(expected_po, @entries.to_s)
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
  end
end
