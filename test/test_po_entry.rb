# -*- coding: utf-8 -*-

require 'gettext/tools/parser/ruby'

# Most functionality of PoMessage is thoroughly tested together
# with the parser and po file generator. Here only tests for some special
# functionality.
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
      def test_normal
        po = GetText::POEntry.new(:normal)
        po.msgid = 'hello'
        po.references = ["file1:1", "file2:10"]
        assert_equal "#: file1:1 file2:10\nmsgid \"hello\"\nmsgstr \"\"\n", po.to_s

        po.msgctxt = 'context'
        po.msgid_plural = 'hello2'
        # Ignore these properties.
        assert_equal "#: file1:1 file2:10\nmsgid \"hello\"\nmsgstr \"\"\n", po.to_s
      end
    end

    class TestPlural < self
      def test_plural
        po = GetText::POEntry.new(:plural)
        po.msgid = 'hello'
        po.msgid_plural = 'hello2'
        po.references = ["file1:1", "file2:10"]
        assert_equal "#: file1:1 file2:10\nmsgid \"hello\"\nmsgid_plural \"hello2\"\nmsgstr[0] \"\"\nmsgstr[1] \"\"\n", po.to_s

        po.msgctxt = 'context'
        # Ignore this property
        assert_equal "#: file1:1 file2:10\nmsgid \"hello\"\nmsgid_plural \"hello2\"\nmsgstr[0] \"\"\nmsgstr[1] \"\"\n", po.to_s
      end
    end

    class TestMessageContext < self
      def test_msgctxt
        po = GetText::POEntry.new(:msgctxt)
        po.msgctxt = 'context'
        po.msgid = 'hello'
        po.references = ["file1:1", "file2:10"]
        assert_equal "#: file1:1 file2:10\nmsgctxt \"context\"\nmsgid \"hello\"\nmsgstr \"\"\n", po.to_s
      end

      def test_msgctxt_plural
        po = GetText::POEntry.new(:msgctxt_plural)
        po.msgctxt = 'context'
        po.msgid = 'hello'
        po.msgid_plural = 'hello2'
        po.references = ["file1:1", "file2:10"]
        assert_equal "#: file1:1 file2:10\nmsgctxt \"context\"\nmsgid \"hello\"\nmsgid_plural \"hello2\"\nmsgstr[0] \"\"\nmsgstr[1] \"\"\n", po.to_s
      end
    end

    class TestInvalid < self
      def test_exception
        po = GetText::POEntry.new(:normal)
        po.references = ["file1:1", "file2:10"]
        assert_raise(GetText::POEntry::NoMsgidError) {po.to_s}

        po.references = nil
        assert_raise(GetText::POEntry::NoMsgidError) {po.to_s}

        po = GetText::POEntry.new(:plural)
        po.msgid = 'hello'
        po.references = ["file1:1", "file2:10"]
        assert_raise(GetText::POEntry::NoMsgidPluralError) {po.to_s}

        po = GetText::POEntry.new(:msgctxt)
        po.msgid = 'hello'
        po.references = ["file1:1", "file2:10"]
        assert_raise(GetText::POEntry::NoMsgctxtError) {po.to_s}

        po = GetText::POEntry.new(:msgctxt_plural)
        po.msgctxt = 'context'
        po.msgid = 'hello'
        po.references = ["file1:1", "file2:10"]
        assert_raise(GetText::POEntry::NoMsgidPluralError) {po.to_s}
      end
    end

    def test_header
      po = GetText::POEntry.new(:normal)
      po.msgid = ""
      po.msgstr = "This is the header entry."
      po.references = nil
      expected_header = <<EOH
msgid ""
msgstr "This is the header entry."
EOH
      assert_equal(expected_header, po.to_s)
    end

    class TestMessageString < self
      def test_msgstr
        po = GetText::POEntry.new(:normal)
        po.msgid = "hello"
        po.msgstr = "Bonjour"
        po.references = ["file1:1", "file2:10"]
        expected_entry = <<-EOE
#: file1:1 file2:10
msgid "hello"
msgstr "Bonjour"
EOE
        assert_equal(expected_entry, po.to_s)
      end

      def test_escaped_msgstr
         po = GetText::POEntry.new(:normal)
         po.msgid = "He said \"hello.\""
         po.msgstr = "Il a dit \"bonjour.\""
         po.references = ["file1:1", "file2:10"]
         expected_entry = <<-EOE
#: file1:1 file2:10
msgid "He said \\\"hello.\\\""
msgstr "Il a dit \\\"bonjour.\\\""
EOE
        assert_equal(expected_entry, po.to_s)
      end

      def test_escaped_msgstr_with_msgid_plural
        po = GetText::POEntry.new(:plural)
        po.msgid = "He said \"hello.\""
        po.msgid_plural = "They said \"hello.\""
        po.msgstr = "Il a dit \"bonjour.\"\000Ils ont dit \"bonjour.\""
        po.references = ["file1:1", "file2:10"]
        expected_entry = <<-EOE
#: file1:1 file2:10
msgid "He said \\\"hello.\\\""
msgid_plural "They said \\\"hello.\\\""
msgstr[0] "Il a dit \\\"bonjour.\\\""
msgstr[1] "Ils ont dit \\\"bonjour.\\\""
EOE
        assert_equal(expected_entry, po.to_s)
      end

      def test_msgstr_with_msgid_plural
        po = GetText::POEntry.new(:plural)
        po.msgid = "he"
        po.msgid_plural = "them"
        po.msgstr = "il\000ils"
        po.references = ["file1:1", "file2:10"]
        expected_entry = <<-EOE
#: file1:1 file2:10
msgid "he"
msgid_plural "them"
msgstr[0] "il"
msgstr[1] "ils"
EOE
        assert_equal(expected_entry, po.to_s)
      end
    end

    def test_obsolete_comment
      po = GetText::POEntry.new(:normal)
      po.msgid = :last
      obsolete_comment =<<EOC
# test.rb:10
msgid \"hello\"
msgstr \"Salut\"
EOC
      po.comment = obsolete_comment

      expected_obsolete_comment = <<-EOC
# test.rb:10
#~ msgid "hello"
#~ msgstr "Salut"
EOC

      assert_equal(expected_obsolete_comment, po.to_s)
    end

    def test_translator_comment
      po = GetText::POEntry.new(:normal)
      po.msgid = "msgid"
      po.msgstr = "msgstr"
      po.translator_comment = "It's the translator comment."

      expected_po =<<EOP
# It's the translator comment.
msgid \"msgid\"
msgstr \"msgstr\"
EOP
      assert_equal(expected_po, po.to_s)
    end

    def test_extracted_comment
      po = GetText::POEntry.new(:normal)
      po.msgid = "msgid"
      po.msgstr = "msgstr"
      po.extracted_comment = "It's the extracted comment."

      expected_po =<<EOP
#. It's the extracted comment.
msgid \"msgid\"
msgstr \"msgstr\"
EOP
      assert_equal(expected_po, po.to_s)
    end

    def test_flag
      po = GetText::POEntry.new(:normal)
      po.msgid = "msgid"
      po.msgstr = "msgstr"
      po.flag = "It's the flag."

      expected_po =<<EOP
#, It's the flag.
msgid \"msgid\"
msgstr \"msgstr\"
EOP
      assert_equal(expected_po, po.to_s)
    end

    def test_previous
      po = GetText::POEntry.new(:normal)
      po.msgid = "msgid"
      po.msgstr = "msgstr"
      po.previous = <<EOC
msgctxt previous_msgctxt
msgid previous_msgid
msgid_plural previous_msgid_plural
EOC

      expected_po =<<EOP
#| msgctxt previous_msgctxt
#| msgid previous_msgid
#| msgid_plural previous_msgid_plural
msgid \"msgid\"
msgstr \"msgstr\"
EOP
      assert_equal(expected_po, po.to_s)
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
