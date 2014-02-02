# Copyright (C) 2014  Kouhei Sutou <kou@clear-code.com>
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

require "tempfile"
require "gettext/tools/msgcat"

class TestToolsMsgCat < Test::Unit::TestCase
  private
  def run_msgcat(input_pos, *options)
    inputs = input_pos.collect do |po|
      input = Tempfile.new("msgcat-input")
      input.write(po)
      input.close
      input
    end
    output = Tempfile.new("msgcat-output")
    GetText::Tools::MsgCat.run("--output", output.path,
                               *inputs.collect(&:path))
    output.read
  end

  class TestHeader < self
    def setup
      @input_po1 = <<-PO
msgid ""
msgstr ""
"Project-Id-Version: gettext 3.0.0\\n"
      PO
      @input_po2 = <<-PO
msgid ""
msgstr ""
"Language: ja\\n"
      PO
    end

    def test_default
      assert_equal(@input_po1, run_msgcat([@input_po1, @input_po2]))
    end
  end

  class TestNoDuplicated < self
    class TestTranslated < self
      def setup
        @input_po1 = <<-PO
msgid "Hello"
msgstr "Bonjour"
        PO

        @input_po2 = <<-PO
msgid "World"
msgstr "Monde"
        PO
      end

      def test_default
        assert_equal(<<-PO.chomp, run_msgcat([@input_po1, @input_po2]))
#{@input_po1}
#{@input_po2}
        PO
      end
    end
  end

  class TestDuplicated < self
    class TestTranslated < self
      class TestSame < self
        def setup
          @po = <<-PO
msgid "Hello"
msgstr "Bonjour"
          PO
        end

        def test_default
          assert_equal(@po, run_msgcat([@po, @po]))
        end
      end

      class TestDifferent < self
        def setup
          @input_po1 = <<-PO
msgid "Hello"
msgstr "Bonjour"
          PO

          @input_po2 = <<-PO
msgid "Hello"
msgstr "Salut"
          PO
        end

        def test_default
          assert_equal(@input_po1, run_msgcat([@input_po1, @input_po2]))
        end
      end
    end
  end
end
