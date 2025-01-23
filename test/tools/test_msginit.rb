# Copyright (C) 2012  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2012-2023  Sutou Kouhei <kou@clear-code.com>
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

require "gettext/tools/msginit"

class TestToolsMsgInit < Test::Unit::TestCase
  def setup
    @msginit = GetText::Tools::MsgInit.new
    stub(@msginit).read_translator_name {translator_name}
    stub(@msginit).read_translator_email {translator_email}

    @year             = "2012"
    @po_revision_date = "2012-09-11 13:19+0900"
    @pot_create_date  = "2012-08-24 11:35+0900"

    stub(@msginit).year          {@year}
    stub(@msginit).revision_date {@po_revision_date}

    Locale.current = "ja_JP.UTF-8"

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        yield
      end
    end
  end

  private
  def current_locale
    Locale.current.to_simple.to_s
  end

  def current_language
    Locale.current.language
  end

  def current_charset
    Locale.current.charset
  end

  def translator_name
    "me"
  end

  def translator_email
    "me@example.com"
  end

  def template_charset
    "CHARSET"
  end

  def create_pot_file(path, options=nil)
    options ||= {}
    File.open(path, "w") do |pot_file|
      pot_file.puts(pot_header(options))
    end
  end

  def default_po_header_options
    {
      :package_name          => default_package_name,
      :first_translator_name => translator_name,
      :translator_name       => translator_name,
      :translator_email      => translator_email,
    }
  end

  def pot_header(options)
    options = default_po_header_options.merge(options)
    package_name = options[:package_name] || default_package_name
    have_plural_forms = options[:have_plural_forms] || true
    charset = options[:charset] || "UTF-8"
    header = <<EOF
# SOME DESCRIPTIVE TITLE.
# Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
#
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: #{package_name} VERSION\\n"
"POT-Creation-Date: #{@pot_create_date}\\n"
"PO-Revision-Date: #{@pot_create_date}\\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
"Language: \\n"
"Language-Team: LANGUAGE <LL@li.org>\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=#{charset}\\n"
"Content-Transfer-Encoding: 8bit\\n"
EOF
    if have_plural_forms
      header += "Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\\n"
    end
    header
  end

  def po_header(locale, language, options={})
    options = default_po_header_options.merge(options)
    package_name = options[:package_name]
    first_translator_name = options[:first_translator_name] || "FIRST AUTHOR"
    name = options[:translator_name] || "FULL NAME"
    email = options[:translator_email] || "EMAIL@ADDRESS"
    language_name = Locale::Info.get_language(language).name
    charset = options[:charset] || "UTF-8"
    plural_forms = @msginit.send(:plural_forms, language)

    <<EOF
# #{language_name} translations for #{package_name} package.
# Copyright (C) #{@year} THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# #{first_translator_name} <#{email}>, #{@year}.
#
msgid ""
msgstr ""
"Project-Id-Version: #{package_name} VERSION\\n"
"POT-Creation-Date: #{@pot_create_date}\\n"
"PO-Revision-Date: #{@po_revision_date}\\n"
"Last-Translator: #{name} <#{email}>\\n"
"Language: #{locale}\\n"
"Language-Team: #{language_name}\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=#{charset}\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: #{plural_forms}\\n"
EOF
  end

  def default_package_name
    "PACKAGE"
  end

  class TestInput < self
    def test_specify_option
      pot_dir = "sub"
      FileUtils.mkdir_p(pot_dir)
      pot_file_path = File.join(pot_dir, "test.pot")
      create_pot_file(pot_file_path)
      @msginit.run("--input", pot_file_path)
      po_file_path = "#{current_locale}.po"
      assert_path_exist(po_file_path)
    end

    def test_find_pot
      pot_in_current_directory = "test.pot"
      create_pot_file(pot_in_current_directory)
      @msginit.run
      po_file_path = "#{current_locale}.po"
      assert_path_exist(po_file_path)
    end

    def test_pot_not_found
      pot_dir = "sub"
      FileUtils.mkdir_p(pot_dir)
      pot_file_path = File.join(pot_dir, "test.pot")
      create_pot_file(pot_file_path)

      assert_raise(GetText::Tools::MsgInit::ValidationError) do
        @msginit.run
      end
    end
  end

  class TestOutput < self
    def setup
      super do
        @pot_file_path = "test.pot"
        create_pot_file(@pot_file_path)
        yield
      end
    end

    def test_default
      @msginit.run("--input", @pot_file_path)

      po_file_path = "#{current_locale}.po"
      assert_path_exist(po_file_path)
    end

    def test_specify_option
      po_dir = "sub"
      FileUtils.mkdir_p(po_dir)
      po_file_path = File.join(po_dir, "test.po")

      @msginit.run("--input", @pot_file_path,
                   "--output", po_file_path)

      assert_path_exist(po_file_path)
    end
  end

  class TestLocale < self
    def run_msginit(locale, pot_charset=nil)
      create_pot_file("test.pot", charset: pot_charset)
      po_file_path = "output.po"
      @msginit.run("--output", po_file_path,
                   "--locale", locale)
      File.read(po_file_path)
    end

    def test_language
      locale = "en"
      assert_equal(po_header(locale, locale),
                   run_msginit(locale))
    end

    def test_language_region
      locale = "en_US"
      language = "en"
      assert_equal(po_header(locale, language),
                   run_msginit(locale))
    end

    def test_language_region_charset
      locale = "en_US"
      language = "en"
      charset = "UTF-8"
      assert_equal(po_header(locale, language),
                   run_msginit("#{locale}.#{charset}"))
    end

    def test_language_charset_with_template_charset
      locale = "en"
      assert_equal(po_header(locale, locale),
                   run_msginit(locale, template_charset))
    end

    def test_language_region_with_template_charset
      locale = "en_US"
      language = "en"
      assert_equal(po_header(locale, language),
                   run_msginit(locale, template_charset))
    end

    def test_language_region_charset_with_template_charset
      locale = "en_US"
      language = "en"
      charset = "UTF-8"
      assert_equal(po_header(locale, language),
                   run_msginit("#{locale}.#{charset}", template_charset))
    end
  end

  class TestCurrentCharset < self
    def run_msginit(pot_charset)
      create_pot_file("test.pot", charset: pot_charset)
      po_file_path = "output.po"
      @msginit.run("--output", po_file_path)
      File.read(po_file_path)
    end

    def po_header(options)
      super(current_locale, current_language, options)
    end

    def test_template_charset
      assert_equal(po_header(charset: current_charset),
                   run_msginit(template_charset))
    end

    def test_no_template_charset
      assert_equal(po_header(charset: "ASCII"),
                   run_msginit("ASCII"))
    end
  end

  class TestTranslator < self
    def run_msginit(*arguments)
      create_pot_file("test.pot")
      po_file_path = "output.po"
      @msginit.run("--output", po_file_path,
                   *arguments)
      File.read(po_file_path)
    end

    class TestChanged < self
      def po_header(options)
        super(current_locale, current_language, options)
      end

      def test_name
        name = "Custom Translator"
        assert_equal(po_header(:first_translator_name => name,
                               :translator_name => name),
                     run_msginit("--translator-name", name))
      end

      def test_email
        email = "custom-translator@example.com"
        assert_equal(po_header(:translator_email => email),
                     run_msginit("--translator-email", email))
      end
    end

    class TestNotChanged < self
      def no_translator_po_header
        po_header(current_locale, current_language,
                  :first_translator_name => nil,
                  :translator_name => nil,
                  :translator_email => nil)
      end

      def test_no_name_no_email
        stub(@msginit).read_translator_name {nil}
        stub(@msginit).read_translator_email {nil}

        assert_equal(no_translator_po_header,
                     run_msginit)
      end

      def test_no_name
        stub(@msginit).read_translator_name {nil}

        assert_equal(no_translator_po_header,
                     run_msginit)
      end

      def test_no_email
        stub(@msginit).read_translator_email {nil}

        assert_equal(no_translator_po_header,
                     run_msginit)
      end

      def test_no_translator
        assert_equal(no_translator_po_header,
                     run_msginit("--no-translator"))
      end
    end
  end

  class TestPackage < self
    def run_msginit
      create_pot_file("test.pot")
      po_file_path = "output.po"
      @msginit.run("--output", po_file_path)
      File.read(po_file_path)
    end

    class TestCustomPackageName < self
      def default_po_header_options
        super.merge(:package_name => "test-package")
      end

      def test_not_change
        assert_equal(po_header(current_locale, current_language),
                     run_msginit)
      end
    end
  end

  class TestPluralForms < self
    def setup
      omit("Red Datasets is required") unless defined?(Datasets::CLDRPlurals)
      super do
        yield
      end
    end

    def run_msginit(pot_header_options={})
      create_pot_file("test.pot", pot_header_options)
      po_file_path = "output.po"
      @msginit.run("--output", po_file_path)
      File.read(po_file_path)
    end

    class TestNoInPot < self
      def test_no_plural_forms_in_pot
        assert_equal(po_header(current_locale, current_language),
                     run_msginit(:have_plural_forms => false))
      end
    end

    def test_ja
      assert_equal("nplurals=1; plural=0;",
                   @msginit.__send__(:plural_forms, "ja"))
    end

    def test_en
      assert_equal("nplurals=2; plural=n != 1;",
                   @msginit.__send__(:plural_forms, "en"))
    end

    def test_fr
      assert_equal("nplurals=2; plural=n > 1;",
                   @msginit.__send__(:plural_forms, "fr"))
    end

    def test_lv
      assert_equal("nplurals=3; " +
                   "plural=((n % 10) == 1) && ((n % 100) != 11) ? 0 : " +
                   "((n % 10) == 0) || ((n % 100) >= 11 && (n % 100) <= 19) " +
                   "? 1 : 2;",
                   @msginit.__send__(:plural_forms, "lv"))
    end

    def test_ga
      assert_equal("nplurals=5; " +
                   "plural=(n == 1) ? 0 : (n == 2) ? 1 : " +
                   "(n >= 3 && n <= 6) ? 2 : (n >= 7 && n <= 10) ? 3 : 4;",
                   @msginit.__send__(:plural_forms, "ga"))
    end

    def test_ro
      assert_equal("nplurals=3; " +
                   "plural=(n == 1) ? 0 : " +
                   "(n == 0) || (n != 1) && ((n % 100) >= 1 && (n % 100) <= 19) ? 1 : 2;",
                   @msginit.__send__(:plural_forms, "ro"))
    end

    def test_lt
      assert_equal("nplurals=3; " +
                   "plural=((n % 10) == 1) && " +
                   "((n % 100) < 11 || (n % 100) > 19) ? 0 : " +
                   "((n % 10) >= 2 && (n % 10) <= 9) && " +
                   "((n % 100) < 11 || (n % 100) > 19) ? 1 : 2;",
                   @msginit.__send__(:plural_forms, "lt"))
    end

    def test_ru
      assert_equal("nplurals=3; " +
                   "plural=((n % 10) == 1) && ((n % 100) != 11) ? 0 : " +
                   "((n % 10) >= 2 && (n % 10) <= 4) && " +
                   "((n % 100) < 12 || (n % 100) > 14) ? 1 : 2;",
                   @msginit.__send__(:plural_forms, "ru"))
    end

    def test_cs
      assert_equal("nplurals=3; " +
                   "plural=(n == 1) ? 0 : (n >= 2 && n <= 4) ? 1 : 2;",
                   @msginit.__send__(:plural_forms, "cs"))
    end

    def test_pl
      assert_equal("nplurals=3; " +
                   "plural=(n == 1) ? 0 : " +
                   "((n % 10) >= 2 && (n % 10) <= 4) && " +
                   "((n % 100) < 12 || (n % 100) > 14) ? 1 : 2;",
                   @msginit.__send__(:plural_forms, "pl"))
    end

    def test_sl
      assert_equal("nplurals=4; " +
                   "plural=((n % 100) == 1) ? 0 : " +
                   "((n % 100) == 2) ? 1 : " +
                   "((n % 100) >= 3 && (n % 100) <= 4) ? 2 : 3;",
                   @msginit.__send__(:plural_forms, "sl"))
    end
  end
end
