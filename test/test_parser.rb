# encoding: utf-8

require 'testlib/helper.rb'
require 'gettext/tools/parser/ruby'
require 'gettext/tools/parser/glade'
require 'gettext/tools/parser/erb'

require 'gettext/tools/rgettext'

class TestGetTextParser < Test::Unit::TestCase
  def test_ruby
    @ary = GetText::RGetText.parse(['testlib/gettext.rb'])

    assert_target 'aaa', ['testlib/gettext.rb:10']
    assert_target 'aaa\n', ['testlib/gettext.rb:14']
    assert_target 'bbb\nccc', ['testlib/gettext.rb:18']
    assert_target 'bbb\nccc\nddd\n', ['testlib/gettext.rb:22']
    assert_target 'eee', ['testlib/gettext.rb:29', 'testlib/gettext.rb:33']
    assert_target 'fff', ['testlib/gettext.rb:33']
    assert_target 'ggghhhiii', ['testlib/gettext.rb:37']
    assert_target 'a"b"c"', ['testlib/gettext.rb:43']
    assert_target 'd"e"f"', ['testlib/gettext.rb:47']
    assert_target 'jjj', ['testlib/gettext.rb:51']
    assert_target 'kkk', ['testlib/gettext.rb:52']
    assert_target 'lllmmm', ['testlib/gettext.rb:56']
    assert_target 'nnn\nooo', ['testlib/gettext.rb:64']
    assert_target "\#", ['testlib/gettext.rb:68', 'testlib/gettext.rb:72']
    assert_target "\\taaa", ['testlib/gettext.rb:76']
    assert_target "Here document1\\nHere document2\\n", ['testlib/gettext.rb:80']
    assert_target "Francois Pinard", ['testlib/gettext.rb:99'] do |t|
      assert_match /proper name/, t.comment
      assert_match /Pronunciation/, t.comment
    end
    assert_target "self explaining", ['testlib/gettext.rb:104'] do |t|
      assert_nil t.comment
    end
    # TODO: assert_target "in_quote", ['testlib/gettext.rb:98']
  end

  def test_ruby_N
    @ary = GetText::RGetText.parse(['testlib/N_.rb'])

    assert_target 'aaa', ['testlib/N_.rb:10']
    assert_target 'aaa\n', ['testlib/N_.rb:14']
    assert_target 'bbb\nccc', ['testlib/N_.rb:18']
    assert_target 'bbb\nccc\nddd\n', ['testlib/N_.rb:22']
    assert_target 'eee', ['testlib/N_.rb:29', 'testlib/N_.rb:33']
    assert_target 'fff', ['testlib/N_.rb:33']
    assert_target 'ggghhhiii', ['testlib/N_.rb:37']
    assert_target 'a"b"c"', ['testlib/N_.rb:43']
    assert_target 'd"e"f"', ['testlib/N_.rb:47']
    assert_target 'jjj', ['testlib/N_.rb:51']
    assert_target 'kkk', ['testlib/N_.rb:52']
    assert_target 'lllmmm', ['testlib/N_.rb:56']
    assert_target 'nnn\nooo', ['testlib/N_.rb:64']
  end

  def test_ruby_n
    @ary = GetText::RGetText.parse(['testlib/ngettext.rb'])
    assert_plural_target "aaa", "aaa2", ['testlib/ngettext.rb:10']
    assert_plural_target "bbb\\n", "ccc2\\nccc2", ['testlib/ngettext.rb:14']
    assert_plural_target "ddd\\nddd", "ddd2\\nddd2", ['testlib/ngettext.rb:18']
    assert_plural_target "eee\\neee\\n", "eee2\\neee2\\n", ['testlib/ngettext.rb:23']
    assert_plural_target "ddd\\neee\\n", "ddd\\neee2", ['testlib/ngettext.rb:29']
    assert_plural_target "fff", "fff2", ['testlib/ngettext.rb:36', 'testlib/ngettext.rb:40']
    assert_plural_target "ggg", "ggg2", ['testlib/ngettext.rb:40']
    assert_plural_target "ggghhhiii", "jjjkkklll", ['testlib/ngettext.rb:44']
    assert_plural_target "a\"b\"c\"", "a\"b\"c\"2", ['testlib/ngettext.rb:53']
    assert_plural_target "mmmmmm", "mmm2mmm2", ['testlib/ngettext.rb:61']
    assert_plural_target "nnn", "nnn2", ['testlib/ngettext.rb:62']
    assert_plural_target "comment", "comments", ['testlib/ngettext.rb:78'] do |t|
      assert_equal "please provide translations for all\n the plural forms!", t.comment
    end
  end

  def test_ruby_p
    @ary = GetText::RGetText.parse(['testlib/pgettext.rb'])
    assert_target_in_context "AAA", "BBB", ["testlib/pgettext.rb:10", "testlib/pgettext.rb:14"]
    assert_target_in_context "AAA|BBB", "CCC", ["testlib/pgettext.rb:18"]
    assert_target_in_context "AAA", "CCC", ["testlib/pgettext.rb:22"]
    assert_target_in_context "CCC", "BBB", ["testlib/pgettext.rb:26"]
    assert_target_in_context "program", "name", ['testlib/pgettext.rb:36'] do |t|
      assert_equal "please translate 'name' in the context of 'program'.\n Hint: the translation should NOT contain the translation of 'program'.", t.comment
    end
  end

  def test_glade
    # Old style (~2.0.4)
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
    @ary = GetText::ErbParser.parse('testlib/erb.rhtml')

    assert_target 'aaa', ['testlib/erb.rhtml:8']
    assert_target 'aaa\n', ['testlib/erb.rhtml:11']
    assert_target 'bbb', ['testlib/erb.rhtml:12']
    assert_plural_target "ccc1", "ccc2", ['testlib/erb.rhtml:13']
  end

  def test_rgettext_parse
    GetText::ErbParser.init(:extnames => ['.rhtml', '.rxml'])
    @ary = GetText::RGetText.parse(['testlib/erb.rhtml'])
    assert_target 'aaa', ['testlib/erb.rhtml:8']
    assert_target 'aaa\n', ['testlib/erb.rhtml:11']
    assert_target 'bbb', ['testlib/erb.rhtml:12']
    assert_plural_target "ccc1", "ccc2", ['testlib/erb.rhtml:13']

    @ary = GetText::RGetText.parse(['testlib/erb.rxml'])
    assert_target 'aaa', ['testlib/erb.rxml:9']
    assert_target 'aaa\n', ['testlib/erb.rxml:12']
    assert_target 'bbb', ['testlib/erb.rxml:13']
    assert_plural_target "ccc1", "ccc2", ['testlib/erb.rxml:14']

    @ary = GetText::RGetText.parse(['testlib/ngettext.rb'])
    assert_plural_target "ooo", "ppp", ['testlib/ngettext.rb:66', 'testlib/ngettext.rb:67']
    assert_plural_target "qqq", "rrr", ['testlib/ngettext.rb:71', 'testlib/ngettext.rb:72']
  end

  private

  def assert_target(msgid, sources = nil)
    t = @ary.detect {|elem| elem.msgid == msgid}
    if t
      if sources
        assert_equal sources.sort, t.sources.sort, 'Translation target sources do not match.'
      end
      yield t if block_given?
    else
      flunk "Expected a translation target with id '#{msgid}'. Not found."
    end
  end

  def assert_plural_target(msgid, plural, sources = nil)
    assert_target msgid, sources do |t|
      assert_equal plural, t.msgid_plural, 'Expected plural form'
      yield t if block_given?
    end
  end

  def assert_target_in_context(msgctxt, msgid, sources = nil)
    t = @ary.detect {|elem| elem.msgid == msgid && elem.msgctxt == msgctxt}
    if t
      if sources
        assert_equal sources.sort, t.sources.sort, 'Translation target sources do not match.'
      end
      yield t if block_given?
    else
      flunk "Expected a translation target with id '#{msgid}' and context '#{msgctxt}'. Not found."
    end
  end
end
