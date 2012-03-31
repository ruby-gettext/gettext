# encoding: utf-8

require 'testlib/helper.rb'
require 'gettext/runtime/mofile'

class TestMOFile < Test::Unit::TestCase
  def test_non_ascii
    mo = load_mo("non_ascii.mo")
    assert_equal("Hello in Japanese", mo["こんにちは"])
  end

  def load_mo(file)
    GetText::MOFile.open("locale/ja/LC_MESSAGES/#{file}", "UTF-8")
  end
end
