require 'test/unit'

require 'gettext'
require 'testlib/simple'

class TestTextDomain < Test::Unit::TestCase
  def setup
    GetText.locale = "ja_JP.eucJP"
  end

  def test_textdomain_path
    test = Simple.new
    assert_equal("japanese", test.test)
    prefix = GetText::TextDomain::CONFIG_PREFIX
    default_locale_dirs = [
      "#{Config::CONFIG['datadir']}/locale/%{lang}/LC_MESSAGES/%{name}.mo",
      "#{Config::CONFIG['datadir'].gsub(/\/local/, "")}/locale/%{lang}/LC_MESSAGES/%{name}.mo",
      "#{prefix}/share/locale/%{lang}/LC_MESSAGES/%{name}.mo",
      "#{prefix}/local/share/locale/%{lang}/LC_MESSAGES/%{name}.mo"
    ].uniq
    assert_equal(default_locale_dirs, GetText::TextDomain::DEFAULT_LOCALE_PATHS)
    new_path = "/foo/%{lang}/%{name}.mo"
    GetText::TextDomain.add_default_locale_path(new_path)
    assert_equal([new_path] + default_locale_dirs, GetText::TextDomain::DEFAULT_LOCALE_PATHS)
  end

end
