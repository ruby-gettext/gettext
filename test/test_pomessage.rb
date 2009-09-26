require 'testlib/helper.rb'
require 'gettext/tools/parser/ruby'

# Most functionality of PoMessage is thoroughly tested together 
# with the parser and po file generator. Here only tests for some special 
# functionality.
class TestPoMessage < Test::Unit::TestCase

  def test_context_match
    tt1 = GetText::PoMessage.new(:msgctxt)
    tt1.msgid = 'hello'
    tt1.msgctxt = 'world'
    tt2 = GetText::PoMessage.new(:normal)
    tt2.msgid = 'hello'
    assert_raise GetText::ParseError do
      tt1.merge tt2
    end
  end

  def test_attribute_accumulation
    tt = GetText::PoMessage.new(:plural)
    tt.set_current_attribute 'long'
    tt.set_current_attribute ' tail'
    tt.advance_to_next_attribute
    tt.set_current_attribute 'long tails'
    assert_equal 'long tail', tt.msgid
    assert_equal 'long tails', tt.msgid_plural
  end
end
