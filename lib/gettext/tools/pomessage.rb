module GetText
  class ParseError < StandardError
  end

  # Contains data related to the expression or sentence that
  # is to be translated.
  class PoMessage
    # Required
    attr_accessor :type          # :normal, :plural, :msgctxt, :msgctxt_plural 
    attr_accessor :msgid
    # Options
    attr_accessor :msgid_plural
    attr_accessor :msgctxt
    attr_accessor :file_name_line_nos    # ["file1:line1", "file2:line2", ...]
    attr_accessor :comment

    # Create the object. +type+ should be :normal, :plural, :msgctxt or :msgctxt_plural. 
    def initialize(type)
      @type = type
      @file_name_line_nos = []
    end

    # Support for extracted comments. Explanation s.
    # http://www.gnu.org/software/gettext/manual/gettext.html#Names
    def add_comment(new_comment)
      if (new_comment and ! new_comment.empty?)
        @comment ||= ""
        @comment += new_comment
      end
      to_s
    end

    # Returns a parameter representation suitable for po-files
    # and other purposes.
    def escaped(param_name)
      orig = self.send param_name
      orig.gsub(/"/, '\"').gsub(/\r/, '')
    end

    # Checks if the other translation target is mergeable with
    # the current one. Relevant are msgid and translation context (msgctxt).
    def matches?(other)
      other.msgid == self.msgid && other.msgctxt == self.msgctxt
    end

    # Merges two translation targets with the same msgid and returns the merged
    # result. If one is declared as plural and the other not, then the one
    # with the plural wins.
    def merge(other)
      return self unless other
      raise ParseError, "Translation targets do not match: \n" \
      "  self: #{self.inspect}\n  other: '#{other.inspect}'" unless matches?(other)
      if other.msgid_plural && !self.msgid_plural
        res = other
        unless (res.file_name_line_nos.include? self.file_name_line_nos[0])
          res.file_name_line_nos += self.file_name_line_nos
          res.add_comment(self.comment)
        end
      else
        res = self
        unless (res.file_name_line_nos.include? other.file_name_line_nos[0])
          res.file_name_line_nos += other.file_name_line_nos
          res.add_comment(other.comment)
        end
      end
      res
    end

    private

    # sets or extends the value of a translation target params like msgid,
    # msgctxt etc.
    #   param is symbol with the name of param
    #   value - new value
    def set_value(param, value)
      send "#{param}=", (send(param) || '') + value.gsub(/\n/, '\n')
    end

    public
    # For backward comatibility. This doesn't support "comment".
    # ary = [msgid1, "file1:line1", "file2:line"]
    def self.new_from_ary(msgid, *file_name_line_nos)
      type = :normal
      msgctxt = nil
      msgid_plural = nil
      
      if msgid.include? "\004"
        msgctxt, msgid = msgid.split(/\004/)
        type = :msgctxt
      end
      if msgid.include? "\000"
        ids = msgid.split(/\000/)
        msgid = ids[0]
        msgid_plural = ids[1]
        if type == :msgctxt
          type = :msgctxt_plural
        else
          type = :plural
        end
      end
      ret = self.new(type)
      ret.msgid = msgid
      ret.file_name_line_nos = file_name_line_nos
      ret.msgctxt = msgctxt
      ret.msgid_plural = msgid_plural
    end
  end
  
end
