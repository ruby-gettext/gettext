# -*- coding: utf-8 -*-

require 'gettext/mo'

class TestMo < Test::Unit::TestCase
  def test_not_exist_msgid
    mo = load_mo("_.mo")
    assert_equal(nil, mo["notexistent"])
  end

  def test_untranslated
    mo = load_mo("untranslated.mo")
    assert_false(mo.has_key?("untranslated"))
    assert_equal(nil, mo["untranslated"])
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

  def test_normalize_charset
    GetText::MO.open('locale/ja/LC_MESSAGES/non_ascii.mo', 'utf8')
  end

  def load_mo(file)
    GetText::MO.open("locale/ja/LC_MESSAGES/#{file}", "UTF-8")
  end
end
