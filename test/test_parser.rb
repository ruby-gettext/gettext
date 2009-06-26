require 'testlib/helper.rb'
require 'gettext/parser/ruby'
require 'gettext/parser/glade'
require 'gettext/parser/erb'

require 'gettext/tools/rgettext'

class TestGetTextParser < Test::Unit::TestCase
  def test_ruby
    ary = GetText::RubyParser.parse('testlib/gettext.rb')

    assert_equal(['aaa', 'testlib/gettext.rb:8'], ary[0])
    assert_equal(['aaa\n', 'testlib/gettext.rb:12'], ary[1])
    assert_equal(['bbb\nccc', 'testlib/gettext.rb:16'], ary[2])
    assert_equal(['bbb\nccc\nddd\n', 'testlib/gettext.rb:20'], ary[3])
    assert_equal(['eee', 'testlib/gettext.rb:27', 'testlib/gettext.rb:31'], ary[4])
    assert_equal(['fff', 'testlib/gettext.rb:31'], ary[5])
    assert_equal(['ggghhhiii', 'testlib/gettext.rb:35'], ary[6])
    assert_equal(['a"b"c"', 'testlib/gettext.rb:41'], ary[7])
    assert_equal(['d"e"f"', 'testlib/gettext.rb:45'], ary[8])
    assert_equal(['jjj', 'testlib/gettext.rb:49'], ary[9])
    assert_equal(['kkk', 'testlib/gettext.rb:50'], ary[10])
    assert_equal(['lllmmm', 'testlib/gettext.rb:54'], ary[11])
    assert_equal(['nnn\nooo', 'testlib/gettext.rb:62'], ary[12])
    assert_equal(["\#", 'testlib/gettext.rb:66', 'testlib/gettext.rb:70'], ary[13])
    assert_equal(["\\taaa", 'testlib/gettext.rb:74'], ary[14])
    assert_equal(["Here document1\\nHere document2\\n", 'testlib/gettext.rb:78'], ary[15])
    assert_equal(["Francois Pinard", 'testlib/gettext.rb:97'], ary[16])
    assert_match(/proper name/, ary[16].extracted_comment)
    assert_match(/Pronunciation/, ary[16].extracted_comment)
    assert_equal(["self explaining", 'testlib/gettext.rb:102'], ary[17])
    assert_nil ary[17].extracted_comment
#    assert_equal(["in_quote", 'testlib/gettext.rb:96'], ary[16])
  end

  def test_ruby_N
    ary = GetText::RubyParser.parse('testlib/N_.rb')

    assert_equal(['aaa', 'testlib/N_.rb:8'], ary[0])
    assert_equal(['aaa\n', 'testlib/N_.rb:12'], ary[1])
    assert_equal(['bbb\nccc', 'testlib/N_.rb:16'], ary[2])
    assert_equal(['bbb\nccc\nddd\n', 'testlib/N_.rb:20'], ary[3])
    assert_equal(['eee', 'testlib/N_.rb:27', 'testlib/N_.rb:31'], ary[4])
    assert_equal(['fff', 'testlib/N_.rb:31'], ary[5])
    assert_equal(['ggghhhiii', 'testlib/N_.rb:35'], ary[6])
    assert_equal(['a"b"c"', 'testlib/N_.rb:41'], ary[7])
    assert_equal(['d"e"f"', 'testlib/N_.rb:45'], ary[8])
    assert_equal(['jjj', 'testlib/N_.rb:49'], ary[9])
    assert_equal(['kkk', 'testlib/N_.rb:50'], ary[10])
    assert_equal(['lllmmm', 'testlib/N_.rb:54'], ary[11])
    assert_equal(['nnn\nooo', 'testlib/N_.rb:62'], ary[12])
  end

  def test_ruby_n
    ary = GetText::RubyParser.parse('testlib/ngettext.rb')
    assert_equal(["aaa\000aaa2", 'testlib/ngettext.rb:8'], ary[0])
    assert_equal(["bbb\\n\000ccc2\\nccc2", 'testlib/ngettext.rb:12'], ary[1])
    assert_equal(["ddd\\nddd\000ddd2\\nddd2", 'testlib/ngettext.rb:16'], ary[2])
    assert_equal(["eee\\neee\\n\000eee2\\neee2\\n", 'testlib/ngettext.rb:21'], ary[3])
    assert_equal(["ddd\\neee\\n\000ddd\\neee2", 'testlib/ngettext.rb:27'], ary[4])
    assert_equal(["fff\000fff2", 'testlib/ngettext.rb:34', 'testlib/ngettext.rb:38'], ary[5])
    assert_equal(["ggg\000ggg2", 'testlib/ngettext.rb:38'], ary[6])
    assert_equal(["ggghhhiii\000jjjkkklll", 'testlib/ngettext.rb:42'], ary[7])
    assert_equal(["a\"b\"c\"\000a\"b\"c\"2", 'testlib/ngettext.rb:51'], ary[8])
    assert_equal(["mmmmmm\000mmm2mmm2", 'testlib/ngettext.rb:59'], ary[10])
    assert_equal(["nnn\000nnn2", 'testlib/ngettext.rb:60'], ary[11])
    assert_equal(["comment\000comments", 'testlib/ngettext.rb:76'], ary[16])
    assert_equal("please provide translations for all \n the plural forms!", ary[16].extracted_comment)
  end
  
  def test_ruby_p
    ary = GetText::RubyParser.parse('testlib/pgettext.rb')
    assert_equal(["AAA\004BBB", "testlib/pgettext.rb:8", "testlib/pgettext.rb:12"], ary[0])
    assert_equal(["AAA|BBB\004CCC", "testlib/pgettext.rb:16"], ary[1])
    assert_equal(["AAA\004CCC", "testlib/pgettext.rb:20"], ary[2])
    assert_equal(["CCC\004BBB", "testlib/pgettext.rb:24"], ary[3])
    assert_equal(["program\004name", 'testlib/pgettext.rb:34'], ary[5])
    assert_equal("please translate 'name' in the context of 'program'.\n Hint: the translation should NOT contain the translation of 'program'.", ary[5].extracted_comment)
  end

  def test_glade
    ary = GetText::GladeParser.parse('testlib/gladeparser.glade')

    assert_equal(['window1', 'testlib/gladeparser.glade:8'], ary[0])
    assert_equal(['normal text', 'testlib/gladeparser.glade:29'], ary[1])
    assert_equal(['1st line\n2nd line\n3rd line', 'testlib/gladeparser.glade:50'], ary[2])
    assert_equal(['<span color="red" weight="bold" size="large">markup </span>', 'testlib/gladeparser.glade:73'], ary[3])
    assert_equal(['<span color="red">1st line markup </span>\n<span color="blue">2nd line markup</span>', 'testlib/gladeparser.glade:94'], ary[4])
    assert_equal(['<span>&quot;markup&quot; with &lt;escaped strings&gt;</span>', 'testlib/gladeparser.glade:116'], ary[5])
    assert_equal(['duplicated', 'testlib/gladeparser.glade:137', 'testlib/gladeparser.glade:158'], ary[6])
  end

  def testlib_erb
    ary = GetText::ErbParser.parse('testlib/erb.rhtml')

    assert_equal(['aaa', 'testlib/erb.rhtml:8'], ary[0])
    assert_equal(['aaa\n', 'testlib/erb.rhtml:11'], ary[1])
    assert_equal(['bbb', 'testlib/erb.rhtml:12'], ary[2])
    assert_equal(["ccc1\000ccc2", 'testlib/erb.rhtml:13'], ary[3])
  end

  def test_rgettext_parse
    GetText::ErbParser.init(:extnames => ['.rhtml', '.rxml'])
    ary = GetText::RGetText.parse(['testlib/erb.rhtml'])
    assert_equal(['aaa', 'testlib/erb.rhtml:8'], ary[0])
    assert_equal(['aaa\n', 'testlib/erb.rhtml:11'], ary[1])
    assert_equal(['bbb', 'testlib/erb.rhtml:12'], ary[2])
    assert_equal(["ccc1\000ccc2", 'testlib/erb.rhtml:13'], ary[3])

    ary = GetText::RGetText.parse(['testlib/erb.rxml'])
    assert_equal(['aaa', 'testlib/erb.rxml:9'], ary[0])
    assert_equal(['aaa\n', 'testlib/erb.rxml:12'], ary[1])
    assert_equal(['bbb', 'testlib/erb.rxml:13'], ary[2])
    assert_equal(["ccc1\000ccc2", 'testlib/erb.rxml:14'], ary[3])


    ary = GetText::RGetText.parse(['testlib/ngettext.rb'])
    assert_equal(["ooo\000ppp", 'testlib/ngettext.rb:64', 'testlib/ngettext.rb:65'], ary[12])
    assert_equal(["qqq\000rrr", 'testlib/ngettext.rb:69', 'testlib/ngettext.rb:70'], ary[13])
  end

end
