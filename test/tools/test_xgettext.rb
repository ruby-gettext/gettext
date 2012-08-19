# -*- coding: utf-8 -*-
#
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

require "gettext/tools/xgettext"

class TestToolsXGetText < Test::Unit::TestCase
  include GetTextTestUtils

  def setup
    @xgettext = GetText::Tools::XGetText.new
    @now = Time.parse("2012-08-19 18:10+0900")
    stub(@xgettext).now {@now}
  end

  setup :setup_tmpdir
  teardown :teardown_tmpdir

  setup
  def setup_paths
    @rb_file_path = File.join(@tmpdir, "lib", "xgettext.rb")
    @pot_file_path = File.join(@tmpdir, "po", "xgettext.pot")
    FileUtils.mkdir_p(File.dirname(@rb_file_path))
    FileUtils.mkdir_p(File.dirname(@pot_file_path))
  end

  def test_relative_source
    File.open(@rb_file_path, "w") do |rb_file|
      rb_file.puts(<<-EOR)
_("Hello")
EOR
    end

    @xgettext.run("--output", @pot_file_path, @rb_file_path)

    assert_equal(<<-EOP, File.read(@pot_file_path))
#{header}
#: ../lib/xgettext.rb:1
msgid "Hello"
msgstr ""
EOP
  end

  private
  def header
    time = @now.strftime("%Y-%m-%d %H:%M%z")
    <<-"EOH"
# SOME DESCRIPTIVE TITLE.
# Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
#
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\\n"
"POT-Creation-Date: #{time}\\n"
"PO-Revision-Date: #{time}\\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
"Language-Team: LANGUAGE <LL@li.org>\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\\n"
EOH
  end
end
