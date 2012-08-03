# -*- coding: utf-8 -*-

require "testlib/helper"
require "gettext/tools/rmsginit"
require "tmpdir"
require "rr"

class TestRMsgInit < Test::Unit::TestCase
  def setup
    Locale.current = "ja_JP.UTF-8"
    stub(GetText::RMsgInit).get_translator_full_name{translator_full_name}
    stub(GetText::RMsgInit).get_translator_mail{translator_mail}
    @time = Time.now.strftime("%Y-%m-%d %H:%M%z")
  end

  def test_all_options
    Dir.mktmpdir do |dir|
      pot_file = create_pot_file
      po_file_path = File.join(dir, "test.po")
      locale = "en"
      language = locale

      GetText::RMsgInit.run("--input", pot_file.path,
                            "--output", po_file_path,
                            "--locale", locale)

      actual_po_header = normalize_po_header(po_file_path)
      assert_equal(expected_po_header(locale, language), actual_po_header)
    end
  end

  def test_locale_including_language
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        create_pot_file
        locale = "en"
        language = locale
        po_file_path = "#{locale}.po"

        GetText::RMsgInit.run("--locale", locale)

        actual_po_header = normalize_po_header(po_file_path)
        assert_equal(expected_po_header(locale, language), actual_po_header)
      end
    end
  end

  def test_locale_including_language_and_region
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        create_pot_file
        locale = "en_US"
        language = "en"
        po_file_path = "#{locale}.po"

        GetText::RMsgInit.run("--locale", locale)

        actual_po_header = normalize_po_header(po_file_path)
        assert_equal(expected_po_header(locale, language), actual_po_header)
      end
    end
  end

  def test_locale_including_language_and_region_with_charset
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        create_pot_file
        locale = "en_US"
        language = "en"
        charset = "UTF-8"
        po_file_path = "en_US.po"

        GetText::RMsgInit.run("--locale", "#{locale}.#{charset}")

        actual_po_header = normalize_po_header(po_file_path)
        assert_equal(expected_po_header(locale, language), actual_po_header)
      end
    end
  end

  def test_pot_file_and_po_file
    Dir.mktmpdir do |dir|
      pot_file = create_pot_file
      locale = current_locale
      language = current_language
      po_file_path = File.join(dir, "test.po")

      GetText::RMsgInit.run("--input", pot_file.path,
                            "--output", po_file_path)

      actual_po_header = normalize_po_header(po_file_path)
      assert_equal(expected_po_header(locale, language), actual_po_header)
    end
  end

  def test_pot_file
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        pot_file = create_pot_file
        locale = current_locale
        language = current_language
        po_file_path = "#{locale}.po"

        GetText::RMsgInit.run("--input", pot_file.path)

        actual_po_header = normalize_po_header(po_file_path)
        assert_equal(expected_po_header(locale, language), actual_po_header)
      end
    end
  end

  def test_no_options
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        create_pot_file
        locale = current_locale
        language = current_language
        po_file_path = "#{locale}.po"

        GetText::RMsgInit.run

        actual_po_header = normalize_po_header(po_file_path)
       assert_equal(expected_po_header(locale, language), actual_po_header)
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

  def create_pot_file
    file = File.new("test.pot", "w")
    file.puts <<EOF
# SOME DESCRIPTIVE TITLE.
# Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
#
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\\n"
"POT-Creation-Date: #{@time}\\n"
"PO-Revision-Date: #{@time}\\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
"Language: \\n"
"Language-Team: LANGUAGE <LL@li.org>\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\\n"
EOF
    file.close
    file
  end

  def normalize_po_header(po_file_path)
    po_file = ""
    File.open(po_file_path) do |file|
      po_file = file.read
    end
    po_file = po_file.gsub(/#{Regexp.escape(@time)}/, "YEAR-MO-DA HO:MI+ZONE")
    po_file.gsub(/#{Time.now.year}/, "YYYY")
  end

  def expected_po_header(locale, language)
    full_name = translator_full_name
    mail = translator_mail
    language_name = Locale::Info.get_language(language).name
    plural_forms = GetText::RMsgInit.plural_forms(language)

<<EOF
# #{language_name} translations for PACKAGE package.
# Copyright (C) YYYY THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# #{full_name} <#{mail}>, YYYY.
#
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\\n"
"POT-Creation-Date: YEAR-MO-DA HO:MI+ZONE\\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n"
"Last-Translator: #{full_name} <#{mail}>\\n"
"Language: #{locale}\\n"
"Language-Team: #{language_name}\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: #{plural_forms}\\n"
EOF
  end
end
