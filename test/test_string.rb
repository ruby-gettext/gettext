require 'testlib/helper.rb'

class TestGetTextString < Test::Unit::TestCase
  def test_sprintf
    assert_equal("foo is a number", "%{msg} is a number" % {:msg => "foo"})
    assert_equal("bar is a number", "%s is a number" % ["bar"])
    assert_equal("bar is a number", "%s is a number" % "bar")
    assert_equal("1, test", "%{num}, %{record}" % {:num => 1, :record => "test"})
    assert_equal("test, 1", "%{record}, %{num}" % {:num => 1, :record => "test"})
    assert_equal("1, test", "%d, %s" % [1, "test"])
    assert_equal("test, 1", "%2$s, %1$d" % [1, "test"])
    assert_raise(ArgumentError) { "%-%" % [1] }
  end

=begin
  def test_sprintf_lack_argument
    assert_equal("%{num}, test", "%{num}, %{record}" % {:record => "test"})
    assert_equal("%{record}", "%{record}" % {:num => 1})
  end

  def test_sprintf_ruby19
    assert_equal("1", "%<num>d" % {:num => 1})
    assert_equal("1", "%<num>#b" % {:num => 1})
    assert_equal("foo", "%<msg>s" % {:msg => "foo"})
    assert_equal("1.000000", "%<num>f" % {:num => 1.0})
    assert_equal("  1", "%<num>3.0f" % {:num => 1.0})
    assert_equal("100.00", "%<num>2.2f" % {:num => 100.0})
    assert_equal("0x64", "%<num>#x" % {:num => 100.0})
  end

  def test_percent
    assert_equal("% 1", "%% %<num>d" % {:num => 1.0})
  end
=end

end
