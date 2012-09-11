# encoding: utf-8

require 'gettext'

class NotExistedMsgid
  include GetText
  bindtextdomain("not_existed_msgid", :path => "locale")

  def not_existed_msgid
  end
end
