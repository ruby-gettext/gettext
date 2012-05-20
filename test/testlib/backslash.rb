# encoding: utf-8

require 'gettext'

class Backslash
  include GetText
  bindtextdomain("backslash", :path => "locale")

  def backslash_in_message
    _("You should escape '\\' as '\\\\'.")
  end
end
