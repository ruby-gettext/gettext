# encoding: utf-8

require 'testlib/helper'
require 'gettext/tools/rmsginit'
require 'tmpdir'
require 'rr'

class TestRMsgInit < Test::Unit::TestCase
  def setup
    stub(GetText::RMsgInit).get_translator_metadata{translator_metadata}
    @time = Time.now.strftime("%Y-%m-%d %H:%M%z")
  end

  def test_all_options
    Dir.mktmpdir do |dir|
      pot_file = create_pot_file
      po_file_path = File.join(dir, "test.po")

      GetText::RMsgInit.run(pot_file.path, po_file_path, "ja")

      actual_po_file = normalize_po_file(po_file_path)
      assert_equal(expected_ja_po_file, actual_po_file)
    end
  end

  def test_locale
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        create_pot_file
        locale = "fr"
        po_file_path = "#{locale}.po"

        GetText::RMsgInit.run(nil, nil, locale)

        actual_po_file = normalize_po_file(po_file_path)
        assert_equal(expected_fr_po_file, actual_po_file)
      end
    end
  end

  def test_pot_file_and_po_file
    Dir.mktmpdir do |dir|
      pot_file = create_pot_file
      po_file_path = File.join(dir, "test.po")

      GetText::RMsgInit.run(pot_file.path, po_file_path)

      actual_po_file = normalize_po_file(po_file_path)
      assert_equal(expected_ja_po_file, actual_po_file)
    end
  end

  def test_pot_file
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        pot_file = create_pot_file
        po_file_path = "ja.po"

        GetText::RMsgInit.run(pot_file.path)

        actual_po_file = normalize_po_file(po_file_path)
        assert_equal(expected_ja_po_file, actual_po_file)
      end
    end
  end

  def test_no_options
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        create_pot_file
        po_file_path = "ja.po"

        GetText::RMsgInit.run

        actual_po_file = normalize_po_file(po_file_path)
        assert_equal(expected_ja_po_file, actual_po_file)
      end
    end
  end

  private
  def translator_metadata
    ["me", "me@example.com"]
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

  def normalize_po_file(po_file_path)
    po_file = ""
    File.open(po_file_path) do |file|
      po_file = file.read
    end
    po_file = po_file.gsub(/#{Regexp.escape(@time)}/, "YEAR-MO-DA HO:MI+ZONE")
    po_file.gsub(/#{Time.now.year}/, "YYYY")
  end

  def expected_ja_po_file
    translator, mail = translator_metadata
<<EOF
# Japanese translations for PACKAGE package.
# Copyright (C) YYYY THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# #{translator} <#{mail}>, YYYY.
#
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\\n"
"POT-Creation-Date: YEAR-MO-DA HO:MI+ZONE\\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n"
"Last-Translator: #{translator} <#{mail}>\\n"
"Language: ja\\n"
"Language-Team: Japanese\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: nplurals=1; plural=0;\\n"
EOF
  end

  def expected_fr_po_file
    translator, mail = translator_metadata
<<EOF
# French translations for PACKAGE package.
# Copyright (C) YYYY THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# #{translator} <#{mail}>, YYYY.
#
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\\n"
"POT-Creation-Date: YEAR-MO-DA HO:MI+ZONE\\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n"
"Last-Translator: #{translator} <#{mail}>\\n"
"Language: fr\\n"
"Language-Team: French\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: nplurals=2; plural=n>1;\\n"
EOF
  end
end
