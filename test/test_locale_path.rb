require 'testlib/helper.rb'
require 'testlib/simple'

class TestLocalePath < Test::Unit::TestCase
  def setup
    GetText.locale = "ja_JP.eucJP"
    GetText::LocalePath.clear
  end

  def test_locale_path
    test = Simple.new
    assert_equal("japanese", test.test)
    prefix = GetText::LocalePath::CONFIG_PREFIX
    default_locale_dirs = [
      "#{Config::CONFIG['datadir']}/locale/%{lang}/LC_MESSAGES/%{name}.mo",
      "#{Config::CONFIG['datadir'].gsub(/\/local/, "")}/locale/%{lang}/LC_MESSAGES/%{name}.mo",
      "#{prefix}/share/locale/%{lang}/LC_MESSAGES/%{name}.mo",
      "#{prefix}/local/share/locale/%{lang}/LC_MESSAGES/%{name}.mo"
    ].uniq
    assert_equal(default_locale_dirs, GetText::LocalePath::DEFAULT_RULES)
    new_path = "/foo/%{lang}/%{name}.mo"
    GetText::LocalePath.add_default_rule(new_path)
    assert_equal([new_path] + default_locale_dirs, GetText::LocalePath::DEFAULT_RULES)
  end

  def test_initialize_with_topdir
    testdir = File.dirname(File.expand_path(__FILE__))
    path = GetText::LocalePath.new("test1", "#{testdir}/locale")
    assert_equal path.locale_paths, ["#{testdir}/locale/%{lang}/LC_MESSAGES/test1.mo", 
                                     "#{testdir}/locale/%{lang}/test1.mo"]
    assert_equal path.current_path(Locale::Tag.parse("ja")), "#{testdir}/locale/ja/LC_MESSAGES/test1.mo"
    assert_equal path.current_path(Locale::Tag.parse("ja-JP")), "#{testdir}/locale/ja/LC_MESSAGES/test1.mo"
    assert_equal path.current_path(Locale::Tag.parse("ja_JP.UTF-8")), "#{testdir}/locale/ja/LC_MESSAGES/test1.mo"
    assert_equal path.current_path(Locale::Tag.parse("en")), nil
  end

end
