require 'testlib/helper.rb'
require 'gettext'
require 'gettext/tools/rgettext.rb'
require 'stringio'

class TestPoGeneration < Test::Unit::TestCase
  def test_extracted_comments
    GetText::RGetText.run(
      File.join(File.dirname(__FILE__), 'testlib/gettext.rb'), 
      out = StringIO.new)
    res = out.string

    # Use following to debug the content of the
    # created file: File.open('/tmp/test.po', 'w').write(res)

    assert_match '#. "Fran\u00e7ois" or (with HTML entities) "Fran&ccedil;ois".', res
    assert_no_match /Ignored/, res, 'Only comments starting with TRANSLATORS should be extracted'
    assert_no_match /TRANSLATORS: This is a proper name/, res, 'The prefix "TRANSLATORS:" should be skipped'
  end

  def test_ary_for_backward_compatibility
    ary = [["window1", "hello_glade2.glade:9"],
           ["first line\nsecond line\nthird line", "hello_glade2.glade:30"],
           ["<Hello world>", "hello_glade2.glade:54", "hello_glade2.glade:64"]]

    str = GetText::RGetText.generate_pot(ary)
    assert_equal str, <<EOS

#: hello_glade2.glade:9
msgid "window1"
msgstr ""

#: hello_glade2.glade:30
msgid "first line\nsecond line\nthird line"
msgstr ""

#: hello_glade2.glade:54 hello_glade2.glade:64
msgid "<Hello world>"
msgstr ""
EOS
  end
end
