# encoding: utf-8

require 'testlib/helper'
require 'gettext/tools/rmsgmerge'

class TestRMsgMerge < Test::Unit::TestCase
  def test_po_data_should_generate_msgctxt
    msg_id = "Context\004Translation"
    
    po_data = GetText::RMsgMerge::PoData.new
    po_data[msg_id] = "Translated"
    po_data.set_comment(msg_id, "#no comment")

    result = po_data.generate_po_entry(msg_id)

    expected = "#no comment\nmsgctxt \"Context\"\nmsgid \"Translation\"\nmsgstr \"Translated\"\n\n"
    assert_equal expected, result
  end
end