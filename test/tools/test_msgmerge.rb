# -*- coding: utf-8 -*-
#
# Copyright (C) 2012  Kouhei Sutou <kou@clear-code.com>
# Copyright (C) 2010  Eddie Lau <tatonlto@gmail.com>
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

require 'gettext/tools/msgmerge'

class TestToolsMsgMerge < Test::Unit::TestCase
  class TestPoData < self
    def setup
      @po_data = GetText::Tools::MsgMerge::PoData.new
    end

    def test_generate_po
      header_entry_comment = "# header entry comment."
      header_entry = "header entry"
      comment = "#: test.rb:10"
      msgid = "Hello"
      msgstr = "Salut"
      expected_po = <<EOP
#{header_entry_comment}
msgid \"\"
msgstr \"\"
\"#{header_entry}\\n\"

#{comment}
msgid \"#{msgid}\"
msgstr \"#{msgstr}\"
EOP

      po = GetText::Tools::MsgMerge::PoData.new
      po.set_comment("", header_entry_comment)
      po[""] = header_entry
      po[msgid] = msgstr
      po.set_comment(msgid, comment)

      assert_equal(expected_po, po.generate_po)
    end

    def test_generate_po_including_obsolete_comment
      obsolete_comment = <<EOC
#. #: test.rb:10
#. msgid \"Hello\"
#. msgstr \"Salut\"
EOC
      obsolete_comment = obsolete_comment.chomp

      header_entry_comment = "# header entry comment."
      header_entry = "header entry"
      expected_po = <<EOP
#{header_entry_comment}
msgid \"\"
msgstr \"\"
\"#{header_entry}\\n\"

#{obsolete_comment}
EOP

      po = GetText::Tools::MsgMerge::PoData.new
      po.set_comment("", header_entry_comment)
      po[""] = header_entry
      po.set_comment(:last, obsolete_comment)

      assert_equal(expected_po, po.generate_po)
    end

    def test_generate_po_msgid_plural_and_empty_msgstr
      msgid = "Singular message\000Plural message"

      @po_data[""] = "Plural-Forms: nplurals=2; plural=n != 1;\\n"
      @po_data[msgid] = ""
      @po_data.set_comment(msgid, "# plural message")
      actual_po = @po_data.generate_po_entry(msgid)
      expected_po = <<'EOE'
# plural message
msgid "Singular message"
msgid_plural "Plural message"
msgstr[0] ""
msgstr[1] ""
EOE
      assert_equal(expected_po, actual_po)
    end

    class TestGeneratePoEntry < self
      def test_msgid_plural
        msgid = "Singular message\000Plural message"

        @po_data[msgid] = "Singular translation\000Plural translation"
        @po_data.set_comment(msgid, "#plural message")
        actual_po = @po_data.generate_po_entry(msgid)
        expected_po = <<'EOE'
#plural message
msgid "Singular message"
msgid_plural "Plural message"
msgstr[0] "Singular translation"
msgstr[1] "Plural translation"
EOE
        assert_equal(expected_po, actual_po)
      end

      def test_msgctxt
        msg_id = "Context\004Translation"
        @po_data[msg_id] = "Translated"
        @po_data.set_comment(msg_id, "#no comment")

        entry = @po_data.generate_po_entry(msg_id)
        assert_equal(<<-'EOE', entry)
#no comment
msgctxt "Context"
msgid "Translation"
msgstr "Translated"
EOE
      end
    end
  end

  class TestMerge < self
    include GetTextTestUtils

    def setup
      @msgmerge = GetText::Tools::MsgMerge.new
    end

    setup :setup_tmpdir
    teardown :teardown_tmpdir

    setup
    def setup_paths
      @pot_file_path = File.join(@tmpdir, "po", "msgmerge.pot")
      @po_file_path = File.join(@tmpdir, "po", "ja", "msgmerge.po")
      FileUtils.mkdir_p(File.dirname(@po_file_path))
    end

    setup
    def setup_content
      @pot_formatted_time = "2012-08-19 19:08+0900"
      @po_formatted_time = "2012-08-19 18:59+0900"
      File.open(@pot_file_path, "w") do |pot_file|
        pot_file.puts(pot_content)
      end

      File.open(@po_file_path, "w") do |po_file|
        po_file.puts(po_content)
      end
    end

    private
    def pot_content
      <<-EOP
# SOME DESCRIPTIVE TITLE.
# Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
#
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\\n"
"POT-Creation-Date: #{@pot_formatted_time}\\n"
"PO-Revision-Date: #{@pot_formatted_time}\\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
"Language-Team: LANGUAGE <LL@li.org>\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\\n"

#: hello.rb:1
msgid "Hello"
msgstr ""

#: hello.rb:2
msgid "World"
msgstr ""
EOP
    end

    def po_header(creation_date, revision_date)
      <<-EOH
# Hello Application.
# Copyright (C) 2012 Kouhei Sutou <kou@clear-code.com>
# This file is distributed under the same license as the Hello package.
# Kouhei Sutou <kou@clear-code.com> , 2012.
#
msgid ""
msgstr ""
"Project-Id-Version: Hello 1.0.0\\n"
"POT-Creation-Date: #{creation_date}\\n"
"PO-Revision-Date: #{revision_date}\\n"
"Last-Translator: Kouhei Sutou <kou@clear-code.com>\\n"
"Language-Team: Japanese <hello-ja@example.com>\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: nplurals=1; plural=0;\\n"
EOH
    end

    def po_content
      <<-EOP
#{po_header(@po_formatted_time, @po_formatted_time)}

#: hello.rb:1
msgid "World"
msgstr "Translated World"
EOP
    end

    class TestFuzzy < self
      def test_header_message
        @msgmerge.run(@po_file_path, @pot_file_path, "--output", @po_file_path)
        assert_equal(<<-EOP, File.read(@po_file_path))
#{po_header(@pot_formatted_time, @po_formatted_time)}
#: hello.rb:1
msgid "Hello"
msgstr ""

#: hello.rb:2
msgid "World"
msgstr "Translated World"
EOP
      end
    end
  end
end
