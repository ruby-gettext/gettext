# encoding: utf-8

require 'gettext'
require 'gettext/tools/rgettext.rb'
require "tmpdir"

class TestPoGeneration < Test::Unit::TestCase
  def test_extracted_comments
    input_file = File.join(File.dirname(__FILE__), 'testlib/gettext.rb')
    res = ""
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        out = "comments.pot"
        GetText.rgettext(input_file, "-o", out)
        res = File.read(out)
      end
    end
    # Use following to debug the content of the
    # created file: File.open('/tmp/test.po', 'w').write(res)

    assert_match '#. "Fran\u00e7ois" or (with HTML entities) "Fran&ccedil;ois".', res
    assert_no_match /Ignored/, res, 'Only comments starting with TRANSLATORS should be extracted'
    assert_no_match /TRANSLATORS: This is a proper name/, res, 'The prefix "TRANSLATORS:" should be skipped'
  end
end
