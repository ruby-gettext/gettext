require 'testlib/helper'

require 'gettext/tools'
class TestToolsTools < Test::Unit::TestCase
  def test_msgmerge_merges_old_and_new_po_file
    old = backup('simple_1.po')
    GetText.msgmerge(old,path('simple_2.po'),'X',:msgmerge=>[:sort_output,:no_location])
    assert_equal File.read(old), <<EOF
msgid "a"
msgstr "b"

#~ msgid "x"
#~ msgstr "y"
EOF
  end

  def test_msgmerge_inserts_the_new_version
    old = backup('version.po')
    GetText.msgmerge(old,path('version.po'),'NEW')
    assert File.read(old) =~ /"Project-Id-Version: NEW\\n"/
  end

private

  def backup(name)
    copy = path(name+".bak")
    FileUtils.cp path(name), copy
    copy
  end

  def path(name)
    File.join(File.dirname(__FILE__),'files',name)
  end
end