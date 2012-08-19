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
  def test_po_data_should_generate_msgctxt
    msg_id = "Context\004Translation"

    po_data = GetText::Tools::MsgMerge::PoData.new
    po_data[msg_id] = "Translated"
    po_data.set_comment(msg_id, "#no comment")

    result = po_data.generate_po_entry(msg_id)

    expected = "#no comment\nmsgctxt \"Context\"\nmsgid \"Translation\"\nmsgstr \"Translated\"\n\n"
    assert_equal expected, result
  end
end
