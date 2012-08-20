# -*- coding: utf-8 -*-
#
# Copyright (C) 2012  Kouhei Sutou <kou@clear-code.com>
# Copyright (C) 2012  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2010  masone (Christian Felder) <ema@rh-productions.ch>
# Copyright (C) 2009  Masao Mutoh
# Copyright (C) 2009  Vladimir Dobriakov <vladimir@geekq.net>
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

require 'gettext'
require 'gettext/tools/xgettext.rb'

class TestPoGeneration < Test::Unit::TestCase
  def test_obsolute_comment
    po_content = <<'EOP'
# SOME DESCRIPTIVE TITLE.
# Copyright (C) YEAR ORGANIZATION
# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
#
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\n"
"POT-Creation-Date: 2002-01-01 02:24:56+0900\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\n"
"Language-Team: LANGUAGE <LL@li.org>\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=utf-8\n"
"Content-Transfer-Encoding: ENCODING\n"

#: test.rb:10
msgid "Hello"
msgstr "Bonjour"

#. #: test.rb:10
#. msgid "Hello"
#. msgstr "Salut"
EOP
    input_file = Tempfile.new("comment.po")
    input_file.print(po_content)
    input_file.close

    parsed_po = GetText::Tools::MsgMerge::PoData.new
    parser = GetText::PoParser.new
    parser.parse_file(input_file.path, parsed_po)

    assert_equal(po_content, parsed_po.generate_po)
  end

  def test_extracted_comments
    input_file = File.join(File.dirname(__FILE__), 'fixtures/_.rb')
    res = ""
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        out = "comments.pot"
        GetText::Tools::XGetText.run(input_file, "-o", out)
        res = File.read(out)
      end
    end
    # Use following to debug the content of the
    # created file: File.open('/tmp/test.po', 'w').write(res)

    assert_match '#. "Fran\u00e7ois" or (with HTML entities) "Fran&ccedil;ois".', res
    assert_no_match /Ignored/, res, 'Only comments starting with TRANSLATORS should be extracted'
    assert_no_match /TRANSLATORS: This is a proper name/, res, 'The prefix "TRANSLATORS:" should be skipped'
  end
end
