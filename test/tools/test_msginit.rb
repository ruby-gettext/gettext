# -*- coding: utf-8 -*-
#
# Copyright (C) 2012  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2012  Kouhei Sutou <kou@clear-code.com>
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
    stub(@msginit).read_translator_full_name {translator_full_name}
    stub(@msginit).read_translator_mail {translator_mail}

    @year             = "2012"
    @po_revision_date = "2012-09-11 13:19+0900"
    @pot_create_date  = "2012-08-24 11:35+0900"

    stub(@msginit).year          {@year}
    stub(@msginit).revision_date {@po_revision_date}

    Locale.current = "ja_JP.UTF-8"
  end

  def test_all_options
    Dir.mktmpdir do |dir|
      pot_file_path = File.join(dir, "test.pot")
      create_pot_file(pot_file_path)
      po_file_path = File.join(dir, "test.po")
      locale = "en"
      language = locale

      @msginit.run("--input", pot_file_path,
                   "--output", po_file_path,
                   "--locale", locale)

      actual_po_header = File.read(po_file_path)
      expected_po_header = po_header(locale, language)
      assert_equal(expected_po_header, actual_po_header)
    end
  end

  def test_locale_including_language
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        create_pot_file("test.pot")
        locale = "en"
        language = locale
        po_file_path = "#{locale}.po"

        @msginit.run("--locale", locale)

        actual_po_header = File.read(po_file_path)
        expected_po_header = po_header(locale, language)
        assert_equal(expected_po_header, actual_po_header)
      end
    end
  end

  def test_locale_including_language_and_region
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        create_pot_file("test.pot")
        locale = "en_US"
        language = "en"
        po_file_path = "#{locale}.po"

        @msginit.run("--locale", locale)

        actual_po_header = File.read(po_file_path)
        expected_po_header = po_header(locale, language)
        assert_equal(expected_po_header, actual_po_header)
      end
    end
  end

  def test_locale_including_language_and_region_with_charset
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        create_pot_file("test.pot")
        locale = "en_US"
        language = "en"
        charset = "UTF-8"
        po_file_path = "en_US.po"

        @msginit.run("--locale", "#{locale}.#{charset}")

        actual_po_header = File.read(po_file_path)
        expected_po_header = po_header(locale, language)
        assert_equal(expected_po_header, actual_po_header)
      end
    end
  end

  def test_pot_file_and_po_file
    Dir.mktmpdir do |dir|
      pot_file_path = File.join(dir, "test.pot")
      create_pot_file(pot_file_path)
      locale = current_locale
      language = current_language
      po_file_path = File.join(dir, "test.po")

      @msginit.run("--input", pot_file_path, "--output", po_file_path)

      actual_po_header = File.read(po_file_path)
      expected_po_header = po_header(locale, language)
      assert_equal(expected_po_header, actual_po_header)
    end
  end

  def test_pot_file
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        pot_file_path = "test.pot"
        create_pot_file(pot_file_path)
        locale = current_locale
        language = current_language
        po_file_path = "#{locale}.po"

        @msginit.run("--input", pot_file_path)

        actual_po_header = File.read(po_file_path)
        expected_po_header = po_header(locale, language)
        assert_equal(expected_po_header, actual_po_header)
      end
    end
  end

  def test_no_options
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        create_pot_file("test.pot")
        locale = current_locale
        language = current_language
        po_file_path = "#{locale}.po"

        @msginit.run

        actual_po_header = File.read(po_file_path)
        expected_po_header = po_header(locale, language)
        assert_equal(expected_po_header, actual_po_header)
      end
    end
  end

  def test_no_translator
    stub(@msginit).read_translator_full_name {nil}
    stub(@msginit).read_translator_mail {nil}

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        create_pot_file("test.pot")
        locale = current_locale
        language = current_language
        po_file_path = "#{locale}.po"

        @msginit.run

        actual_po_header = File.read(po_file_path)
        expected_po_header = no_translator_po_header(locale, language)
        assert_equal(expected_po_header, actual_po_header)
      end
    end
  end

  def test_no_translator_full_name
    stub(@msginit).read_translator_full_name {nil}

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        create_pot_file("test.pot")
        locale = current_locale
        language = current_language
        po_file_path = "#{locale}.po"

        @msginit.run

        actual_po_header = File.read(po_file_path)
        expected_po_header = no_translator_po_header(locale, language)
        assert_equal(expected_po_header, actual_po_header)
      end
    end
  end

  def test_no_translator_mail
    stub(@msginit).read_translator_mail {nil}

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        create_pot_file("test.pot")
        locale = current_locale
        language = current_language
        po_file_path = "#{locale}.po"

        @msginit.run

        actual_po_header = File.read(po_file_path)
        expected_po_header = no_translator_po_header(locale, language)
        assert_equal(expected_po_header, actual_po_header)
      end
    end
  end

  def test_package_name_specified_in_project_id_version
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        pot_file_name = "test.pot"
        options = {:package_name => "test-package"}
        create_pot_file(pot_file_name, options)
        locale = current_locale
        language = current_language
        po_file_path = "#{locale}.po"

        @msginit.run("--input", pot_file_name)

        expected_po_header = po_header(locale, language, options)
        actual_po_header = File.read(po_file_path)

        assert_equal(expected_po_header, actual_po_header)
      end
    end

    def test_no_plural_forms
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          options = {:have_plural_forms => false}
          create_pot_file("test.pot", options)
          locale = current_locale
          language = current_language
          po_file_path = "#{locale}.po"

          @msginit.run

          actual_po_header = File.read(po_file_path)
          expected_po_header = po_header(locale, language)
          assert_equal(expected_po_header, actual_po_header)
        end
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

  def translator_full_name
    "me"
  end

  def translator_mail
    "me@example.com"
  end

  def create_pot_file(path, options=nil)
    options ||= {}
    File.open(path, "w") do |pot_file|
      pot_file.puts(pot_header(options))
    end
  end

  def pot_header(options)
    package_name = options[:package_name] || default_package_name
    have_plural_forms = options[:have_plural_forms] || true
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
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
EOF
    if have_plural_forms
      header << "Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\\n"
    end
    header
  end

  def po_header(locale, language, options=nil)
    options ||= {}
    package_name = options[:package_name] || default_package_name
    full_name = translator_full_name
    mail = translator_mail
    language_name = Locale::Info.get_language(language).name
    plural_forms = @msginit.send(:plural_forms, language)

    <<EOF
# #{language_name} translations for #{package_name} package.
# Copyright (C) #{@year} THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# #{full_name} <#{mail}>, #{@year}.
#
msgid ""
msgstr ""
"Project-Id-Version: #{package_name} VERSION\\n"
"POT-Creation-Date: #{@pot_create_date}\\n"
"PO-Revision-Date: #{@po_revision_date}\\n"
"Last-Translator: #{full_name} <#{mail}>\\n"
"Language: #{locale}\\n"
"Language-Team: #{language_name}\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: #{plural_forms}\\n"
EOF
  end

  def default_package_name
    "PACKAGE"
  end

  def no_translator_po_header(locale, language)
    language_name = Locale::Info.get_language(language).name
    plural_forms = @msginit.send(:plural_forms, language)

    <<EOF
# #{language_name} translations for PACKAGE package.
# Copyright (C) #{@year} THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# FIRST AUTHOR <EMAIL@ADDRESS>, #{@year}.
#
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\\n"
"POT-Creation-Date: #{@pot_create_date}\\n"
"PO-Revision-Date: #{@po_revision_date}\\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
"Language: #{locale}\\n"
"Language-Team: #{language_name}\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: #{plural_forms}\\n"
EOF
  end
end
