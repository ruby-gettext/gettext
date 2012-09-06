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

class TestRubyParserXXX < Test::Unit::TestCase
  include GetTextTestUtils

  class Test_ < self
    def test_one_line
      assert_parse([
                     {
                       :msgid => "one line",
                       :sources => ["one_line.rb:28"],
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
                       :separator => "$",
                       :sources   => ["custom.rb:28"],
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
                       :separator    => "$",
                       :sources      => ["custom.rb:28"],
                     }
                   ],
                   "custom.rb")
    end

    private
    def fixture_path(*components)
      super("ns_", *components)
    end
  end

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
        :separator    => nil,
        :sources      => nil,
      }
      default.merge(message)
    end
  end

  def normalize_actual(po_messages)
    po_messages.collect do |po_message|
      {
        :msgid        => po_message.msgid,
        :msgid_plural => po_message.msgid_plural,
        :separator    => po_message.separator,
        :sources      => normalize_sources(po_message.sources),
      }
    end
  end

  def normalize_sources(sources)
    sources.collect do |source|
      source.sub(/\A#{Regexp.escape(fixture_path)}\//, "")
    end
  end
end
