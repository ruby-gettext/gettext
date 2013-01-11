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

    def test_msgids
      @po_data["hello"] = "bonjour"
      @po_data["he"] = "il"

      assert_equal(["he", "hello"], @po_data.msgids.sort)
    end

    def test_each_msgids
      @po_data["hello"] = "bonjour"
      @po_data["he"] = "il"
      @po_data[""] = "header"
      @po_data[:last] = ""

      msgids = []
      @po_data.each_msgid do |msgid|
        msgids << msgid
      end
      assert_equal(["he", "hello"], msgids.sort)
    end

    class TestAddToExistingEntry < self
      def test_msgctxt
        msgctxt = "msgctxt"
        msgid = "msgid"
        original_string = "#{msgctxt}\004#{msgid}"
        msgstr = "msgstr"

        po_data = GetText::Tools::MsgMerge::PoData.new
        po_data[original_string] = msgstr

        assert_equal(msgctxt, po_data.po[msgctxt, msgid].msgctxt)
      end

      def test_msgid_plural
        msgid = "msgid"
        msgid_plural = "msgid_plural"
        original_string = "#{msgid}\000#{msgid_plural}"
        msgstr = "msgstr"

        po_data = GetText::Tools::MsgMerge::PoData.new
        po_data[msgid] = msgstr
        assert_equal(nil, po_data.po[msgid].msgid_plural)

        po_data[original_string] = msgstr
        assert_equal(msgid_plural, po_data.po[msgid].msgid_plural)
      end

      def test_msgctxt_and_msgid_plural
        msgctxt = "msgctxt"
        msgid = "msgid"
        msgid_plural = "msgid_plural"
        original_string = "#{msgctxt}\004#{msgid}\000#{msgid_plural}"
        msgstr = "msgstr"

        po_data = GetText::Tools::MsgMerge::PoData.new
        po_data[original_string] = msgstr

        assert_equal(msgctxt, po_data.po[msgctxt, msgid].msgctxt)
        assert_equal(msgid_plural, po_data.po[msgctxt, msgid].msgid_plural)
      end
    end

    class TestGeneratePo < self
      def test_comment_and_msgid_and_msgstr
        header_entry_comment = "# header entry comment."
        header_entry = "header\nentry\n"
        comment = "#: test.rb:10"
        msgid = "Hello"
        msgstr = "Salut"

        po = GetText::Tools::MsgMerge::PoData.new
        po.set_comment("", header_entry_comment)
        po[""] = header_entry
        po[msgid] = msgstr
        po.set_comment(msgid, comment)

        expected_header_entry = ""
        header_entry.each_line do |line|
          expected_header_entry << "\"#{line.chomp}\\n\"\n"
        end
        expected_header_entry = expected_header_entry.chomp
        expected_po = <<EOP
#{header_entry_comment}
msgid \"\"
msgstr \"\"
#{expected_header_entry}

#{comment}
msgid \"#{msgid}\"
msgstr \"#{msgstr}\"
EOP
        assert_equal(expected_po, po.generate_po)
      end

      def test_obsolete_comment
        obsolete_comment =<<EOC
# test.rb:10
msgid \"Hello\"
msgstr \"Salut\"
EOC
        header_entry_comment = "# header entry comment."
        header_entry = "header entry"

        po = GetText::Tools::MsgMerge::PoData.new
        po.set_comment("", header_entry_comment)
        po[""] = header_entry
        po.set_comment(:last, obsolete_comment)

        expected_obsolete_comment = <<-EOC
# test.rb:10
#~ msgid "Hello"
#~ msgstr "Salut"
EOC
        expected_obsolete_comment = expected_obsolete_comment.chomp

        expected_po = <<EOP
#{header_entry_comment}
msgid \"\"
msgstr \"#{header_entry}\"

#{expected_obsolete_comment}
EOP
        assert_equal(expected_po, po.generate_po)
      end

      def test_msgid_plural_and_empty_msgstr
        msgid = "Singular message\000Plural message"

        @po_data[""] = "Plural-Forms: nplurals=2; plural=n != 1;\\n"
        @po_data[msgid] = "\000"
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
    end

    class TestGeneratePOEntry < self
      def test_msgid_plural
        msgid = "Singular message\000Plural message"

        @po_data[msgid] = "Singular translation\000Plural translation"
        @po_data.set_comment(msgid, "# plural message")
        actual_po = @po_data.generate_po_entry(msgid)
        expected_po = <<'EOE'
# plural message
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
        @po_data.set_comment(msg_id, "# no comment")

        entry = @po_data.generate_po_entry(msg_id)
        assert_equal(<<-'EOE', entry)
# no comment
msgctxt "Context"
msgid "Translation"
msgstr "Translated"
EOE
      end
    end
  end

  class TestSplitMsgid < self
    def test_existed_msgctxt_and_msgid_plural
      msgctxt = "msgctxt"
      msgid = "msgid"
      msgid_plural = "msgid_plural"

      assert_equal([msgctxt, msgid, msgid_plural],
                   split_msgid("#{msgctxt}\004#{msgid}\000#{msgid_plural}"))
    end

    def test_existed_msgctxt_only
      msgctxt = "msgctxt"
      msgid = "msgid"

      assert_equal([msgctxt, msgid, nil],
                   split_msgid("#{msgctxt}\004#{msgid}"))
    end

    def test_existed_msgid_plural_only
      msgid = "msgid"
      msgid_plural = "msgid_plural"

      assert_equal([nil, msgid, msgid_plural],
                   split_msgid("#{msgid}\000#{msgid_plural}"))
    end

    def test_not_existed
      msgid = "msgid"

      assert_equal([nil, msgid, nil], split_msgid(msgid))
    end

    def test_empty_msgid
      msgid = ""

      assert_equal([nil, msgid, nil], split_msgid(msgid))
    end

    def test_last_symbol_msgid
      msgid = :last

      assert_equal([nil, msgid, nil], split_msgid(msgid))
    end

    private
    def split_msgid(msgid)
      po_data = GetText::Tools::MsgMerge::PoData.new
      po_data.send(:split_msgid, msgid)
    end
  end

  class TestParseComment < self
    def setup
      @po_data = GetText::Tools::MsgMerge::PoData.new
      @entry = @po_data.send(:generate_entry, "test")
    end

    def test_translator_comment
      comment = "# translator comment"
      parsed_comment = parse_comment(comment).translator_comment
      assert_equal("translator comment\n", parsed_comment)
    end

    def test_extracted_comment
      comment = "#. extracted comment"
      parsed_comment = parse_comment(comment).extracted_comment
      assert_equal("extracted comment\n", parsed_comment)
    end

    def test_references
      comment = "#: reference.rb:10"
      parsed_comment = parse_comment(comment).references
      assert_equal(["reference.rb:10"], parsed_comment)
    end

    def test_flag
      comment = "#, fuzzy"
      parsed_comment = parse_comment(comment).flag
      assert_equal("fuzzy\n", parsed_comment)
    end

    def test_previous
      comment = "#| msgid the previous msgid"
      parsed_comment = parse_comment(comment).previous
      assert_equal("msgid the previous msgid\n", parsed_comment)
    end

    private
    def parse_comment(comment)
      @po_data.send(:parse_comment, comment, @entry)
    end
  end

  class TestMerger < self
    def setup
      @merger = GetText::Tools::MsgMerge::Merger.new
      @po_data = GetText::Tools::MsgMerge::PoData.new
      @po = GetText::PO.new
      @pot = GetText::PO.new
    end

    def test_add_entry
      @po["hello"] = "bonjour"
      @pot["hello"] = "bonjour"
      @pot["he"] = "il"
      merged_po = @merger.merge(@po, @pot)

      assert_equal("bonjour", merged_po["hello"].msgstr)
      assert_equal("il", merged_po["he"].msgstr)
    end

    def test_existing_obsolete_entry
      @po["hello"] = "bonjour"
      @po[:last] = generate_entry(:msgid => :last,
                                  :comment => "#~ obsolete_entry")
      @pot["hello"] = "bonjour"
      merged_po = @merger.merge(@po, @pot)

      assert_equal("bonjour", merged_po["hello"].msgstr)
      assert_nil(merged_po[:last])
    end

    def test_different_msgstr
      @po["hello"] = "salut"
      @pot["hello"] = "bonjour"
      merged_po = @merger.merge(@po, @pot)

      assert_equal("salut", merged_po["hello"].msgstr)
    end

    def test_translator_comment
      @po["hello"] = generate_entry(:msgid => "hello",
                                    :msgstr => "bonjour",
                                    :translator_comment => "comment")

      @pot["hello"] = generate_entry(:msgid => "hello",
                                     :msgstr => "",
                                     :translator_comment => "It's comments")

      merged_po = @merger.merge(@po, @pot)
      assert_equal("bonjour", merged_po["hello"].msgstr)
      assert_equal("comment", merged_po["hello"].translator_comment)
    end

    def test_extracted_comment
      @po["hello"] = generate_entry(:msgid => "hello",
                                    :msgstr => "bonjour",
                                    :extracted_comment => "comment")

      @pot["hello"] = generate_entry(:msgid => "hello",
                                     :msgstr => "",
                                     :extracted_comment => "extracted comments")

      merged_po = @merger.merge(@po, @pot)
      assert_equal("bonjour", merged_po["hello"].msgstr)
      assert_equal("extracted comments", merged_po["hello"].extracted_comment)
    end

    def test_references
      references = ["file.rb:10", "helper.rb:10"]
      pot_references = ["file.rb:10", "test.rb:25"]
      @po["hello"] = generate_entry(:msgid => "hello",
                                    :msgstr => "bonjour",
                                    :references => references)

      @pot["hello"] = generate_entry(:msgid => "hello",
                                     :msgstr => "",
                                     :references => pot_references)

      merged_po = @merger.merge(@po, @pot)
      assert_equal("bonjour", merged_po["hello"].msgstr)
      assert_equal(pot_references, merged_po["hello"].references)
    end

    def test_flag
      @po["hello"] = generate_entry(:msgid => "hello",
                                    :msgstr => "bonjour",
                                    :flag => "c-format")

      @pot["hello"] = generate_entry(:msgid => "hello",
                                     :msgstr => "",
                                     :flag => "no-c-format")

      merged_po = @merger.merge(@po, @pot)
      assert_equal("bonjour", merged_po["hello"].msgstr)
      assert_equal("no-c-format", merged_po["hello"].flag)
    end

    def test_previous
      @po["hello"] = generate_entry(:msgid => "hello",
                                    :msgstr => "bonjour",
                                    :previous => "hi")

      @pot["hello"] = generate_entry(:msgid => "hello",
                                     :msgstr => "")

      merged_po = @merger.merge(@po, @pot)
      assert_equal("bonjour", merged_po["hello"].msgstr)
      assert_equal(nil, merged_po["hello"].previous)
    end

    class TestAddNoFuzzy < self
      def test_add_to_nontranslated_entry
        @po["helol"] = generate_entry(:msgid => "helol",
                                      :msgstr => nil)
        @pot["hello"] = generate_entry(:msgid => "hello",
                                       :msgstr => nil)
        merged_po = @merger.merge(@po, @pot)
        assert_true(merged_po.has_key?("hello"))
        assert_nil(merged_po["hello"].flag)
      end

      def test_fuzzy_header
        @po[""] = generate_entry(:msgid => "",
                                 :msgstr => "header\nentry",
                                 :translator_comment => "header comment")

        @pot[""] = generate_entry(:msgid => "",
                                  :msgstr => "uninitialized\ncomment",
                                  :translator_comment => "uninitialized comment",
                                  :flag => "fuzzy")

        merged_po = @merger.merge(@po, @pot)
        assert_equal("header\nentry", merged_po[""].msgstr)
        assert_equal("header comment", merged_po[""].translator_comment)
        assert_equal(nil, merged_po[""].flag)
      end

      def test_fuzzy_header_including_pot_creation_date
        creation_date_mark = "POT-Creation-Date: "
        po_creation_date = "#{creation_date_mark}2012-11-15 08:15+0900"
        pot_creation_date = "#{creation_date_mark}2012-11-20 14:15+0900"
        @po[""] = generate_entry(:msgid => "",
                                 :msgstr => po_creation_date,
                                 :translator_comment => "header comment")

        @pot[""] = generate_entry(:msgid => "",
                                  :msgstr => pot_creation_date,
                                  :translator_comment => "header comment",
                                  :flag => "fuzzy")

        merged_po = @merger.merge(@po, @pot)
        assert_equal(pot_creation_date, merged_po[""].msgstr)
      end
    end

    class TestAddFuzzy < self
      def test_nonexistent_msgctxt
        @po["normal", "hello"] = generate_entry(:msgctxt => "normal",
                                                :msgid => "hello",
                                                :msgstr => "salut")
        @pot["hello"] = generate_entry(:msgid => "hello",
                                       :msgstr => "")
        merged_po = @merger.merge(@po, @pot)

        assert_false(merged_po.has_key?("normal", "hello"))
        assert_true(merged_po.has_key?("hello"))
        assert_equal("salut", merged_po["hello"].msgstr)
        assert_equal("fuzzy", merged_po["hello"].flag)
      end

      def test_msgid_plural
        @po["he"] = generate_entry(:msgid => "he",
                                   :msgid_plural => "thye",
                                   :msgstr => "il\000ils")
        @pot["he"] = generate_entry(:msgid => "he",
                                    :msgid_plural => "they",
                                    :msgstr => "")
        merged_po = @merger.merge(@po, @pot)

        assert_equal("il\000ils", merged_po["he"].msgstr)
        assert_equal("they", merged_po["he"].msgid_plural)
        assert_equal("fuzzy", merged_po["he"].flag)
      end

      def test_fuzzy_matching_entry
        @po["helol"] = "bonjour"
        @pot["hello"] = ""
        merged_po = @merger.merge(@po, @pot)

        assert_false(merged_po.has_key?("helol"))
        assert_true(merged_po.has_key?("hello"))
        assert_equal("bonjour", merged_po["hello"].msgstr)
        assert_equal("fuzzy", merged_po["hello"].flag)
      end

      def test_merged_entry_from_fuzzy_entry
        @po["hello"] = generate_entry(:msgid => "hello",
                                      :msgstr => "bonjuor",
                                      :flag => "fuzzy")

        @pot["hello"] = generate_entry(:msgid => "hello",
                                       :msgstr => "")

        merged_po = @merger.merge(@po, @pot)
        assert_equal("bonjuor", merged_po["hello"].msgstr)
        assert_equal("fuzzy", merged_po["hello"].flag)
      end
    end

    def test_obsolete_entry
      @po["hello"] = "bonjour"
      @pot["hi"] = "salut"
      merged_po = @merger.merge(@po, @pot)

      assert_equal("salut", merged_po["hi"].msgstr)
      assert_false(merged_po.has_key?("hello"))

      obsolete_comment = <<-EOC
msgid "hello"
msgstr "bonjour"
EOC
      assert_equal(obsolete_comment, merged_po[:last].comment)
    end

    private
    def generate_entry(options)
      msgctxt = options[:msgctxt]
      msgid_plural = options[:msgid_plural]
      type = @po_data.send(:detect_entry_type, msgctxt, msgid_plural)

      entry = GetText::POEntry.new(type)
      entry.translator_comment = options[:translator_comment]
      entry.extracted_comment = options[:extracted_comment]
      entry.references = options[:references] || []
      entry.flag = options[:flag]
      entry.previous = options[:previous]
      entry.msgctxt = msgctxt
      entry.msgid = options[:msgid]
      entry.msgid_plural = msgid_plural
      entry.msgstr = options[:msgstr]
      entry.comment = options[:comment]
      entry
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
