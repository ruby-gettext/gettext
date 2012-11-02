# encoding: utf-8

require 'gettext/tools/parser/ruby'

# Most functionality of PoMessage is thoroughly tested together
# with the parser and po file generator. Here only tests for some special
# functionality.
class TestPoEntry < Test::Unit::TestCase

  def test_context_match
    tt1 = GetText::PoEntry.new(:msgctxt)
    tt1.msgid = 'hello'
    tt1.msgctxt = 'world'
    tt2 = GetText::PoEntry.new(:normal)
    tt2.msgid = 'hello'
    assert_raise GetText::ParseError do
      tt1.merge tt2
    end
  end

  def test_attribute_accumulation
    tt = GetText::PoEntry.new(:plural)
    tt.set_current_attribute 'long'
    tt.set_current_attribute ' tail'
    tt.advance_to_next_attribute
    tt.set_current_attribute 'long tails'
    assert_equal 'long tail', tt.msgid
    assert_equal 'long tails', tt.msgid_plural
  end

  def test_to_s_normal
    po = GetText::PoEntry.new(:normal)
    po.msgid = 'hello'
    po.sources = ["file1:1", "file2:10"]
    assert_equal "#: file1:1 file2:10\nmsgid \"hello\"\nmsgstr \"\"\n", po.to_s

    po.msgctxt = 'context'
    po.msgid_plural = 'hello2'
    # Ignore these properties.
    assert_equal "#: file1:1 file2:10\nmsgid \"hello\"\nmsgstr \"\"\n", po.to_s
  end

  def test_to_s_plural
    po = GetText::PoEntry.new(:plural)
    po.msgid = 'hello'
    po.msgid_plural = 'hello2'
    po.sources = ["file1:1", "file2:10"]
    assert_equal "#: file1:1 file2:10\nmsgid \"hello\"\nmsgid_plural \"hello2\"\nmsgstr[0] \"\"\nmsgstr[1] \"\"\n", po.to_s

    po.msgctxt = 'context'
    # Ignore this property
    assert_equal "#: file1:1 file2:10\nmsgid \"hello\"\nmsgid_plural \"hello2\"\nmsgstr[0] \"\"\nmsgstr[1] \"\"\n", po.to_s
  end

  def test_to_s_msgctxt
    po = GetText::PoEntry.new(:msgctxt)
    po.msgctxt = 'context'
    po.msgid = 'hello'
    po.sources = ["file1:1", "file2:10"]
    assert_equal "#: file1:1 file2:10\nmsgctxt \"context\"\nmsgid \"hello\"\nmsgstr \"\"\n", po.to_s
  end

  def test_to_s_msgctxt_plural
    po = GetText::PoEntry.new(:msgctxt_plural)
    po.msgctxt = 'context'
    po.msgid = 'hello'
    po.msgid_plural = 'hello2'
    po.sources = ["file1:1", "file2:10"]
    assert_equal "#: file1:1 file2:10\nmsgctxt \"context\"\nmsgid \"hello\"\nmsgid_plural \"hello2\"\nmsgstr[0] \"\"\nmsgstr[1] \"\"\n", po.to_s
  end

  def test_to_s_exception
    po = GetText::PoEntry.new(:normal)
    po.sources = ["file1:1", "file2:10"]
    assert_raise(GetText::PoEntry::NoMsgidError) {po.to_s}

    po.sources = nil
    assert_raise(GetText::PoEntry::NoMsgidError) {po.to_s}

    po = GetText::PoEntry.new(:plural)
    po.msgid = 'hello'
    po.sources = ["file1:1", "file2:10"]
    assert_raise(GetText::PoEntry::NoMsgidPluralError) {po.to_s}

    po.msgid_plural = 'hello2'
    po.sources = nil
    assert_raise(GetText::PoEntry::NoSourcesError) {po.to_s}

    po = GetText::PoEntry.new(:msgctxt)
    po.msgid = 'hello'
    po.sources = ["file1:1", "file2:10"]
    assert_raise(GetText::PoEntry::NoMsgctxtError) {po.to_s}

    po = GetText::PoEntry.new(:msgctxt_plural)
    po.msgctxt = 'context'
    po.msgid = 'hello'
    po.sources = ["file1:1", "file2:10"]
    assert_raise(GetText::PoEntry::NoMsgidPluralError) {po.to_s}
  end

  def test_to_s_header
    po = GetText::PoEntry.new(:normal)
    po.msgid = ""
    po.msgstr = "This is the header entry."
    po.sources = nil
    expected_header = <<EOH
msgid ""
msgstr "This is the header entry."
EOH
    assert_equal(expected_header, po.to_s)
  end

  def test_msgstr
    po = GetText::PoEntry.new(:normal)
    po.msgid = "hello"
    po.msgstr = "Bonjour"
    po.sources = ["file1:1", "file2:10"]
    expected_entry = <<-EOE
#: file1:1 file2:10
msgid "hello"
msgstr "Bonjour"
EOE
    assert_equal(expected_entry, po.to_s)
  end

  def test_escaped_msgstr
    po = GetText::PoEntry.new(:normal)
    po.msgid = "He said \"hello.\""
    po.msgstr = "Il a dit \"bonjour.\""
    po.sources = ["file1:1", "file2:10"]
    expected_entry = <<-EOE
#: file1:1 file2:10
msgid "He said \\\"hello.\\\""
msgstr "Il a dit \\\"bonjour.\\\""
EOE
    assert_equal(expected_entry, po.to_s)
  end

  def test_escaped_msgstr_with_msgid_plural
    po = GetText::PoEntry.new(:plural)
    po.msgid = "He said \"hello.\""
    po.msgid_plural = "They said \"hello.\""
    po.msgstr = "Il a dit \"bonjour.\"\000Ils ont dit \"bonjour.\""
    po.sources = ["file1:1", "file2:10"]
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
    po = GetText::PoEntry.new(:plural)
    po.msgid = "he"
    po.msgid_plural = "them"
    po.msgstr = "il\000ils"
    po.sources = ["file1:1", "file2:10"]
    expected_entry = <<-EOE
#: file1:1 file2:10
msgid "he"
msgid_plural "them"
msgstr[0] "il"
msgstr[1] "ils"
EOE
    assert_equal(expected_entry, po.to_s)
  end

  class TestEscape < self
    def setup
      @entry = GetText::PoEntry.new(:normal)
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
      @entry = GetText::PoEntry.new(:normal)
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
      @entry = GetText::PoEntry.new(:normal)
    end

    def test_unformatted_comment
      comment = "comment"
      @entry.msgid = "msgid"
      expected_comment = "#. #{comment}\n"
      assert_equal(expected_comment, @entry.format_comment(comment))
    end

    def test_header_comment
      comment = "comment"
      @entry.msgid = ""
      expected_comment = "# #{comment}\n"
      assert_equal(expected_comment, @entry.format_comment(comment))
    end
  end
end
