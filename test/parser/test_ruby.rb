# -*- coding: utf-8 -*-
#
# Copyright (C) 2012  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2012  Kouhei Sutou <kou@clear-code.com>
# Copyright (C) 2010  masone (Christian Felder) <ema@rh-productions.ch>
# Copyright (C) 2009  Vladimir Dobriakov <vladimir@geekq.net>
# Copyright (C) 2009-2010  Masao Mutoh
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

require "gettext/tools/parser/ruby"

class TestRubyParser < Test::Unit::TestCase
  include GetTextTestUtils

  private
  def parse(file)
    GetText::RubyParser.parse(fixture_path(file))
  end

  def assert_parse(expected, file)
    assert_equal(normalize_expected(expected),
                 normalize_actual(parse(file)))
  end

  def normalize_expected(messages)
    messages.collect do |message|
      default = {
        :msgid        => nil,
        :msgid_plural => nil,
        :msgstr       => nil,
        :separator    => nil,
        :references      => nil,
      }
      default.merge(message)
    end
  end

  def normalize_actual(po)
    po.collect do |po_entry|
      {
        :msgid        => po_entry.msgid,
        :msgid_plural => po_entry.msgid_plural,
        :msgstr       => po_entry.msgstr,
        :separator    => po_entry.separator,
        :references      => normalize_references(po_entry.references),
      }
    end
  end

  def normalize_references(references)
    references.collect do |reference|
      reference.sub(/\A#{Regexp.escape(fixture_path)}\//, "")
    end
  end

  class TestDetectEncoding < self
    setup :need_encoding

    def test_ascii_and_hyphen
      assert_equal("euc-jp", detect_encoding("# coding: euc-jp"))
    end

    def test_number
      assert_equal("cp932", detect_encoding("#coding: cp932"))
    end

    def test_under_bar
      assert_equal("Shift_JIS", detect_encoding("# coding: Shift_JIS"))
    end

    def test_emacs_style
      assert_equal("utf-8", detect_encoding("# -*- coding: utf-8 -*-"))
    end

    def test_encoding
      assert_equal("utf-8", detect_encoding("# encoding: utf-8"))
    end

    def test_equal
      assert_equal("utf-8", detect_encoding("# encoding = utf-8"))
    end

    private
    def detect_encoding(content)
      GetText::RubyParser.detect_encoding(content)
    end

    class NewLineStyle < self
      def test_unix
        assert_equal("utf-8", detect_encoding("# -*- coding: utf-8-unix -*-"))
      end

      def test_mac
        assert_equal("utf-8", detect_encoding("# -*- coding: utf-8-mac -*-"))
      end

      def test_dos
        assert_equal("utf-8", detect_encoding("# -*- coding: utf-8-dos -*-"))
      end
    end
  end

  class Test_ < self
    def test_one_line
      assert_parse([
                     {
                       :msgid => "one line",
                       :references => ["one_line.rb:28"],
                     }
                   ],
                   "one_line.rb")
    end

    private
    def fixture_path(*components)
      super("_", *components)
    end
  end

  class Tests_ < self
    def test_custom
      assert_parse([
                     {
                       :msgid     => "context|context$message",
                       :msgstr    => nil,
                       :separator => "$",
                       :references   => ["custom.rb:28"],
                     }
                   ],
                   "custom.rb")
    end

    private
    def fixture_path(*components)
      super("s_", *components)
    end
  end

  class Testns_ < self
    def test_custom
      assert_parse([
                     {
                       :msgid        => "context|context$message",
                       :msgid_plural => "context|context$messages",
                       :msgstr       => nil,
                       :separator    => "$",
                       :references      => ["custom.rb:28"],
                     }
                   ],
                   "custom.rb")
    end

    private
    def fixture_path(*components)
      super("ns_", *components)
    end
  end
end
