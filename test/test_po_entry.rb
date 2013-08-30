# -*- coding: utf-8 -*-
#
# Copyright (C) 2012  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2012-2013  Kouhei Sutou <kou@clear-code.com>
# Copyright (C) 2010  masone (Christian Felder) <ema@rh-productions.ch>
# Copyright (C) 2009  Masao Mutoh
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

require 'gettext/tools/parser/ruby'

class TestPOEntry < Test::Unit::TestCase

  def test_context_match
    tt1 = GetText::POEntry.new(:msgctxt)
    tt1.msgid = 'hello'
    tt1.msgctxt = 'world'
    tt2 = GetText::POEntry.new(:normal)
    tt2.msgid = 'hello'
    assert_raise GetText::ParseError do
      tt1.merge tt2
    end
  end

  def test_attribute_accumulation
    tt = GetText::POEntry.new(:plural)
    tt.set_current_attribute 'long'
    tt.set_current_attribute ' tail'
    tt.advance_to_next_attribute
    tt.set_current_attribute 'long tails'
    assert_equal 'long tail', tt.msgid
    assert_equal 'long tails', tt.msgid_plural
  end

  class TestSetType < self
    def test_varid_type
      entry = GetText::POEntry.new(:normal)
      type = :plural
      entry.type = type
      assert_equal(type, entry.type)
    end

    def test_invalid_type
      entry = GetText::POEntry.new(:normal)
      type = :invalid
      assert_raise(GetText::POEntry::InvalidTypeError) do
        entry.type = type
      end
      assert_equal(:normal, entry.type)
    end

    def test_invalid_type_for_initializing
      assert_raise(GetText::POEntry::InvalidTypeError) do
        GetText::POEntry.new(:invalid)
      end
    end
  end

  class TestToS < self
    class TestNormal < self
      def setup
        @entry = GetText::POEntry.new(:normal)
      end

      def test_minimum
        @entry.msgid = 'hello'
        @entry.references = ["file1:1", "file2:10"]
        assert_equal(<<-PO, @entry.to_s)
#: file1:1 file2:10
msgid "hello"
msgstr ""
        PO
      end

      def test_with_garbage_information
        @entry.msgid = 'hello'
        @entry.references = ["file1:1", "file2:10"]
        @entry.msgctxt = 'context'
        @entry.msgid_plural = 'hello2'
        assert_equal(<<-PO, @entry.to_s)
#: file1:1 file2:10
msgid "hello"
msgstr ""
        PO
      end

      def test_new_line
        @entry.msgid = "hello\nworld"
        assert_equal(<<-PO, @entry.to_s)
msgid ""
"hello\\n"
"world"
msgstr ""
        PO
      end
    end

    class TestPlural < self
      def setup
        @entry = GetText::POEntry.new(:plural)
      end

      def test_minimum
        @entry.msgid = 'hello'
        @entry.msgid_plural = 'hello2'
        @entry.references = ["file1:1", "file2:10"]
        assert_equal(<<-PO, @entry.to_s)
#: file1:1 file2:10
msgid "hello"
msgid_plural "hello2"
msgstr[0] ""
msgstr[1] ""
        PO
      end

      def test_with_garbage_information
        @entry.msgid = 'hello'
        @entry.msgid_plural = 'hello2'
        @entry.references = ["file1:1", "file2:10"]
        @entry.msgctxt = 'context'
        assert_equal(<<-PO, @entry.to_s)
#: file1:1 file2:10
msgid "hello"
msgid_plural "hello2"
msgstr[0] ""
msgstr[1] ""
        PO
      end
    end

    def test_msgctxt
      entry = GetText::POEntry.new(:msgctxt)
      entry.msgctxt = 'context'
      entry.msgid = 'hello'
      entry.references = ["file1:1", "file2:10"]
      assert_equal(<<-PO, entry.to_s)
#: file1:1 file2:10
msgctxt "context"
msgid "hello"
msgstr ""
      PO
    end

    def test_msgctxt_plural
      entry = GetText::POEntry.new(:msgctxt_plural)
      entry.msgctxt = 'context'
      entry.msgid = 'hello'
      entry.msgid_plural = 'hello2'
      entry.references = ["file1:1", "file2:10"]
      assert_equal(<<-PO, entry.to_s)
#: file1:1 file2:10
msgctxt "context"
msgid "hello"
msgid_plural "hello2"
msgstr[0] ""
msgstr[1] ""
      PO
    end

    class TestInvalid < self
      def test_normal
        entry = GetText::POEntry.new(:normal)
        entry.references = ["file1:1", "file2:10"]
        assert_raise(GetText::POEntry::NoMsgidError) {entry.to_s}
      end

      def test_plural
        entry = GetText::POEntry.new(:plural)
        entry.msgid = 'hello'
        entry.references = ["file1:1", "file2:10"]
        assert_raise(GetText::POEntry::NoMsgidPluralError) {entry.to_s}
      end

      def test_msgctxt
        entry = GetText::POEntry.new(:msgctxt)
        entry.msgid = 'hello'
        entry.references = ["file1:1", "file2:10"]
        assert_raise(GetText::POEntry::NoMsgctxtError) {entry.to_s}
      end

      def test_msgctx_plural
        entry = GetText::POEntry.new(:msgctxt_plural)
        entry.msgctxt = 'context'
        entry.msgid = 'hello'
        entry.references = ["file1:1", "file2:10"]
        assert_raise(GetText::POEntry::NoMsgidPluralError) {entry.to_s}
      end
    end

    def test_header
      entry = GetText::POEntry.new(:normal)
      entry.msgid = ""
      entry.msgstr = "This is the header entry."
      entry.references = nil
      expected_header = <<-EOH
msgid ""
msgstr "This is the header entry."
EOH
      assert_equal(expected_header, entry.to_s)
    end

    class TestMessageString < self
      def test_normal
        entry = GetText::POEntry.new(:normal)
        entry.msgid = "hello"
        entry.msgstr = "Bonjour"
        entry.references = ["file1:1", "file2:10"]
        expected_po = <<-EOE
#: file1:1 file2:10
msgid "hello"
msgstr "Bonjour"
EOE
        assert_equal(expected_po, entry.to_s)
      end

      def test_plural
        entry = GetText::POEntry.new(:plural)
        entry.msgid = "he"
        entry.msgid_plural = "them"
        entry.msgstr = "il\000ils"
        entry.references = ["file1:1", "file2:10"]
        expected_po = <<-EOE
#: file1:1 file2:10
msgid "he"
msgid_plural "them"
msgstr[0] "il"
msgstr[1] "ils"
EOE
        assert_equal(expected_po, entry.to_s)
      end

      class TestEscape < self
        def test_normal
          entry = GetText::POEntry.new(:normal)
          entry.msgid = "He said \"hello.\""
          entry.msgstr = "Il a dit \"bonjour.\""
          entry.references = ["file1:1", "file2:10"]
          expected_po = <<-EOE
#: file1:1 file2:10
msgid "He said \\"hello.\\""
msgstr "Il a dit \\"bonjour.\\""
EOE
          assert_equal(expected_po, entry.to_s)
        end

        def test_plural
          entry = GetText::POEntry.new(:plural)
          entry.msgid = "He said \"hello.\""
          entry.msgid_plural = "They said \"hello.\""
          entry.msgstr = "Il a dit \"bonjour.\"\000Ils ont dit \"bonjour.\""
          entry.references = ["file1:1", "file2:10"]
          expected_po = <<-EOE
#: file1:1 file2:10
msgid "He said \\"hello.\\""
msgid_plural "They said \\"hello.\\""
msgstr[0] "Il a dit \\"bonjour.\\""
msgstr[1] "Ils ont dit \\"bonjour.\\""
EOE
          assert_equal(expected_po, entry.to_s)
        end
      end
    end

    def test_obsolete_comment
      entry = GetText::POEntry.new(:normal)
      entry.msgid = :last
      obsolete_comment = <<-EOC
# test.rb:10
msgid "hello"
msgstr "Salut"
EOC
      entry.comment = obsolete_comment

      expected_obsolete_comment = <<-EOC
# test.rb:10
#~ msgid "hello"
#~ msgstr "Salut"
EOC

      assert_equal(expected_obsolete_comment, entry.to_s)
    end

    def test_translator_comment
      entry = GetText::POEntry.new(:normal)
      entry.msgid = "msgid"
      entry.msgstr = "msgstr"
      entry.translator_comment = "It's the translator comment."

      expected_po = <<-EOP
# It's the translator comment.
msgid "msgid"
msgstr "msgstr"
EOP
      assert_equal(expected_po, entry.to_s)
    end

    def test_extracted_comment
      entry = GetText::POEntry.new(:normal)
      entry.msgid = "msgid"
      entry.msgstr = "msgstr"
      entry.extracted_comment = "It's the extracted comment."

      expected_po = <<-EOP
#. It's the extracted comment.
msgid "msgid"
msgstr "msgstr"
EOP
      assert_equal(expected_po, entry.to_s)
    end

    def test_flag
      entry = GetText::POEntry.new(:normal)
      entry.msgid = "msgid"
      entry.msgstr = "msgstr"
      entry.flag = "It's the flag."

      expected_po = <<-EOP
#, It's the flag.
msgid "msgid"
msgstr "msgstr"
EOP
      assert_equal(expected_po, entry.to_s)
    end

    def test_previous
      entry = GetText::POEntry.new(:normal)
      entry.msgid = "msgid"
      entry.msgstr = "msgstr"
      entry.previous = <<-EOC
msgctxt previous_msgctxt
msgid previous_msgid
msgid_plural previous_msgid_plural
EOC

      expected_po = <<-EOP
#| msgctxt previous_msgctxt
#| msgid previous_msgid
#| msgid_plural previous_msgid_plural
msgid "msgid"
msgstr "msgstr"
EOP
      assert_equal(expected_po, entry.to_s)
    end
  end

  class TestEscape < self
    def setup
      @entry = GetText::POEntry.new(:normal)
    end

    def test_backslash
      @entry.msgid = "You should escape '\\' as '\\\\'."
      assert_equal("You should escape '\\\\' as '\\\\\\\\'.",
                   @entry.escaped(:msgid))
    end

    def test_new_line
      @entry.msgid = "First\nSecond\nThird"
      assert_equal("First\\nSecond\\nThird",
                   @entry.escaped(:msgid))
    end

    def test_tab
      @entry.msgid = "First\tSecond\tThird"
      assert_equal("First\\tSecond\\tThird",
                   @entry.escaped(:msgid))
    end
  end

  class TestFormatMessage < self
    def setup
      @entry = GetText::POEntry.new(:normal)
    end

    def test_including_newline
      message = "line 1\n" +
                  "line 2"
      expected_message = "\"\"\n" +
                          "\"line 1\\n\"\n" +
                          "\"line 2\"\n"
      assert_equal(expected_message, @entry.format_message(message))
    end

    def test_not_existed_newline
      message = "line 1"
      expected_message = "\"line 1\"\n"
      assert_equal(expected_message, @entry.format_message(message))
    end
  end

  class TestFormatComment < self
    def setup
      @entry = GetText::POEntry.new(:normal)
    end

    def test_one_line_comment
      comment = "comment"
      mark = "#"
      @entry.msgid = "msgid"
      expected_comment = "# #{comment}\n"
      assert_equal(expected_comment, @entry.format_comment(mark, comment))
    end

    def test_multiline_comment
      comment = "comment1\ncomment2"
      mark = "#"
      @entry.msgid = ""
      expected_comment = "#{comment.gsub(/^/, "#{mark} ")}\n"
      assert_equal(expected_comment, @entry.format_comment(mark, comment))
    end
  end
end
