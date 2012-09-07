# encoding: utf-8
#
# Copyright (C) 2012  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2012  Kouhei Sutou <kou@clear-code.com>
# Copyright (C) 2010  masone (Christian Felder) <ema@rh-productions.ch>
# Copyright (C) 2009  Vladimir Dobriakov <vladimir@geekq.net>
# Copyright (C) 2009-2010  Masao Mutoh
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

require "tempfile"
require 'gettext/tools/parser/ruby'
require 'gettext/tools/parser/glade'
require 'gettext/tools/parser/erb'

require 'gettext/tools/xgettext'

class TestGetTextParser < Test::Unit::TestCase
  def setup
    @xgettext = GetText::Tools::XGetText.new
  end

  def test_ruby
    @ary = @xgettext.parse(['fixtures/_.rb'])

    assert_target 'aaa\n', ['fixtures/_.rb:34']
    assert_target 'bbb\nccc', ['fixtures/_.rb:38']
    assert_target 'bbb\nccc\nddd\n', ['fixtures/_.rb:42']
    assert_target 'eee', ['fixtures/_.rb:49', 'fixtures/_.rb:53']
    assert_target 'fff', ['fixtures/_.rb:53']
    assert_target 'ggghhhiii', ['fixtures/_.rb:57']
    assert_target 'a"b"c"', ['fixtures/_.rb:63']
    assert_target 'd"e"f"', ['fixtures/_.rb:67']
    assert_target 'jjj', ['fixtures/_.rb:71']
    assert_target 'kkk', ['fixtures/_.rb:72']
    assert_target 'lllmmm', ['fixtures/_.rb:76']
    assert_target 'nnn\nooo', ['fixtures/_.rb:84']
    assert_target "\#", ['fixtures/_.rb:88', 'fixtures/_.rb:92']
    assert_target "\\taaa", ['fixtures/_.rb:96']
    assert_target "Here document1\\nHere document2\\n", ['fixtures/_.rb:100']
    assert_target "Francois Pinard", ['fixtures/_.rb:119'] do |t|
      assert_match(/proper name/, t.comment)
      assert_match(/Pronunciation/, t.comment)
    end

    assert_target("No TRANSLATORS comment", ["fixtures/_.rb:122"]) do |t|
      assert_nil(t.comment)
    end

    assert_target "self explaining", ['fixtures/_.rb:127'] do |t|
      assert_nil t.comment
    end

    assert_target "This is a # including string.", ["fixtures/_.rb:131"]

    # TODO: assert_target "in_quote", ['fixtures/_.rb:118']
  end

  def test_ruby_N
    @ary = @xgettext.parse(['fixtures/N_.rb'])

    assert_target 'aaa', ['fixtures/N_.rb:10']
    assert_target 'aaa\n', ['fixtures/N_.rb:14']
    assert_target 'bbb\nccc', ['fixtures/N_.rb:18']
    assert_target 'bbb\nccc\nddd\n', ['fixtures/N_.rb:22']
    assert_target 'eee', ['fixtures/N_.rb:29', 'fixtures/N_.rb:33']
    assert_target 'fff', ['fixtures/N_.rb:33']
    assert_target 'ggghhhiii', ['fixtures/N_.rb:37']
    assert_target 'a"b"c"', ['fixtures/N_.rb:43']
    assert_target 'd"e"f"', ['fixtures/N_.rb:47']
    assert_target 'jjj', ['fixtures/N_.rb:51']
    assert_target 'kkk', ['fixtures/N_.rb:52']
    assert_target 'lllmmm', ['fixtures/N_.rb:56']
    assert_target 'nnn\nooo', ['fixtures/N_.rb:64']
  end

  def test_ruby_n
    @ary = @xgettext.parse(['fixtures/n_.rb'])
    assert_plural_target "aaa", "aaa2", ['fixtures/n_.rb:29']
    assert_plural_target "bbb\\n", "ccc2\\nccc2", ['fixtures/n_.rb:33']
    assert_plural_target "ddd\\nddd", "ddd2\\nddd2", ['fixtures/n_.rb:37']
    assert_plural_target "eee\\neee\\n", "eee2\\neee2\\n", ['fixtures/n_.rb:42']
    assert_plural_target "ddd\\neee\\n", "ddd\\neee2", ['fixtures/n_.rb:48']
    assert_plural_target "fff", "fff2", ['fixtures/n_.rb:55', 'fixtures/n_.rb:59']
    assert_plural_target "ggg", "ggg2", ['fixtures/n_.rb:59']
    assert_plural_target "ggghhhiii", "jjjkkklll", ['fixtures/n_.rb:63']
    assert_plural_target "a\"b\"c\"", "a\"b\"c\"2", ['fixtures/n_.rb:72']
    assert_plural_target "mmmmmm", "mmm2mmm2", ['fixtures/n_.rb:80']
    assert_plural_target "nnn", "nnn2", ['fixtures/n_.rb:81']
    assert_plural_target "comment", "comments", ['fixtures/n_.rb:97'] do |t|
      assert_equal "please provide translations for all\n the plural forms!", t.comment
    end
  end

  def test_ruby_p
    @ary = @xgettext.parse(['fixtures/p_.rb'])
    assert_target_in_context "AAA", "BBB", ["fixtures/p_.rb:29", "fixtures/p_.rb:33"]
    assert_target_in_context "AAA|BBB", "CCC", ["fixtures/p_.rb:37"]
    assert_target_in_context "AAA", "CCC", ["fixtures/p_.rb:41"]
    assert_target_in_context "CCC", "BBB", ["fixtures/p_.rb:45"]
    assert_target_in_context "program", "name", ['fixtures/p_.rb:55'] do |t|
      assert_equal "please translate 'name' in the context of 'program'.\n Hint: the translation should NOT contain the translation of 'program'.", t.comment
    end
  end

  def test_glade
    # Old style (~2.0.4)
    ary = GetText::GladeParser.parse('fixtures/gladeparser.glade')

    assert_equal(['window1', 'fixtures/gladeparser.glade:8'], ary[0])
    assert_equal(['normal text', 'fixtures/gladeparser.glade:29'], ary[1])
    assert_equal(['1st line\n2nd line\n3rd line', 'fixtures/gladeparser.glade:50'], ary[2])
    assert_equal(['<span color="red" weight="bold" size="large">markup </span>', 'fixtures/gladeparser.glade:73'], ary[3])
    assert_equal(['<span color="red">1st line markup </span>\n<span color="blue">2nd line markup</span>', 'fixtures/gladeparser.glade:94'], ary[4])
    assert_equal(['<span>&quot;markup&quot; with &lt;escaped strings&gt;</span>', 'fixtures/gladeparser.glade:116'], ary[5])
    assert_equal(['duplicated', 'fixtures/gladeparser.glade:137', 'fixtures/gladeparser.glade:158'], ary[6])
  end

  class TestErbParser < self
    include GetTextTestUtils

    def test_detect_encoding
      omit("ERB in Ruby 1.9 is needed for this test.") unless ruby19?

      euc_file = Tempfile.new("euc-jp.rhtml")
      euc_file.open
      euc_file.puts("<%#-*- coding: euc-jp -*-%>")
      euc_file.close

      erb_source = ERB.new(File.read(euc_file.path)).src
      encoding = GetText::ErbParser.detect_encoding(erb_source)

      assert_equal("EUC-JP", encoding)
    end

    def test_ascii
      @ary = GetText::ErbParser.parse('fixtures/erb/ascii.rhtml')

      assert_target 'aaa', ['fixtures/erb/ascii.rhtml:8']
      assert_target 'aaa\n', ['fixtures/erb/ascii.rhtml:11']
      assert_target 'bbb', ['fixtures/erb/ascii.rhtml:12']
      assert_plural_target "ccc1", "ccc2", ['fixtures/erb/ascii.rhtml:13']
    end

    def test_non_ascii
      fixture_path = "fixtures/erb/non_ascii.rhtml"
      @ary = GetText::ErbParser.parse(fixture_path)

      assert_target('わたし', ["#{fixture_path}:11"])
    end
  end

  def test_xgettext_parse
    GetText::ErbParser.init(:extnames => ['.rhtml', '.rxml'])
    @ary = @xgettext.parse(['fixtures/erb/ascii.rhtml'])
    assert_target 'aaa', ['fixtures/erb/ascii.rhtml:8']
    assert_target 'aaa\n', ['fixtures/erb/ascii.rhtml:11']
    assert_target 'bbb', ['fixtures/erb/ascii.rhtml:12']
    assert_plural_target "ccc1", "ccc2", ['fixtures/erb/ascii.rhtml:13']

    @ary = @xgettext.parse(['fixtures/erb/ascii.rxml'])
    assert_target 'aaa', ['fixtures/erb/ascii.rxml:9']
    assert_target 'aaa\n', ['fixtures/erb/ascii.rxml:12']
    assert_target 'bbb', ['fixtures/erb/ascii.rxml:13']
    assert_plural_target "ccc1", "ccc2", ['fixtures/erb/ascii.rxml:14']

    @ary = @xgettext.parse(['fixtures/n_.rb'])
    assert_plural_target "ooo", "ppp", ['fixtures/n_.rb:85', 'fixtures/n_.rb:86']
    assert_plural_target "qqq", "rrr", ['fixtures/n_.rb:90', 'fixtures/n_.rb:91']
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
