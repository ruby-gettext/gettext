# encoding: utf-8

require 'gettext/runtime/mofile'

class TestMoFile < Test::Unit::TestCase
  def test_not_exist_msgid
    mo = load_mo("not_existed_msgid.mo")
    assert_equal(nil, mo["notexist"])
  end

  def test_non_ascii
    mo = load_mo("non_ascii.mo")
    assert_equal("Hello in Japanese", mo["こんにちは"])
  end

  def test_backslash
    mo = load_mo("backslash.mo")
    assert_equal("'\\'は'\\\\'とエスケープするべきです。",
                 mo["You should escape '\\' as '\\\\'."])
  end

  def load_mo(file)
    GetText::MoFile.open("locale/ja/LC_MESSAGES/#{file}", "UTF-8")
  end
end
