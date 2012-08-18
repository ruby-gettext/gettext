require "tempfile"
require "gettext/tools/poparser"

class TestPoParser < Test::Unit::TestCase
  def test_msgstr_not_existing
    po_file = create_po_file(<<-EOP)
msgid "Hello"
msgstr ""
EOP
    messages = parse_po_file(po_file)

    assert_equal("", messages["Hello"])
  end

  private
  def create_po_file(content)
    po_file = Tempfile.new("hello.po")
    po_file.print(content)
    po_file.close
    po_file
  end

  def parse_po_file(po_file)
    parser = GetText::PoParser.new
    parser.parse_file(po_file.path, MoFile.new)
  end

  class FuzzyTest < self
    def setup
      @po = <<-EOP
#, fuzzy
msgid "Hello"
msgstr "Bonjour"
EOP
      @po_file = Tempfile.new("hello.po")
      @po_file.print(@po)
      @po_file.close
    end

    class IgnoreTest < self
      def test_report_warning
        mock($stderr).print("Warning: fuzzy message was ignored.\n")
        mock($stderr).print("  #{@po_file.path}: msgid 'Hello'\n")
        messages = parse do |parser|
          parser.ignore_fuzzy = true
          parser.report_warning = true
        end
        assert_nil(messages["Hello"])
      end

      def test_not_report_warning
        dont_allow($stderr).print("Warning: fuzzy message was ignored.\n")
        dont_allow($stderr).print("  #{@po_file.path}: msgid 'Hello'\n")
        messages = parse do |parser|
          parser.ignore_fuzzy = true
          parser.report_warning = false
        end
        assert_nil(messages["Hello"])
      end
    end

    class NotIgnore < self
      def test_report_warning
        mock($stderr).print("Warning: fuzzy message was used.\n")
        mock($stderr).print("  #{@po_file.path}: msgid 'Hello'\n")
        messages = parse do |parser|
          parser.ignore_fuzzy = false
          parser.report_warning = true
        end
        assert_equal("Bonjour", messages["Hello"])
      end

      def test_not_report_warning
        dont_allow($stderr).print("Warning: fuzzy message was used.\n")
        dont_allow($stderr).print("  #{@po_file.path}: msgid 'Hello'\n")
        messages = parse do |parser|
          parser.ignore_fuzzy = false
          parser.report_warning = false
        end
        assert_equal("Bonjour", messages["Hello"])
      end
    end

    private
    def parse
      parser = GetText::PoParser.new
      class << parser
        def _(message_id)
          message_id
        end
      end
      messages = MoFile.new
      yield parser
      parser.parse_file(@po_file.path, messages)
      messages
    end
  end
end
