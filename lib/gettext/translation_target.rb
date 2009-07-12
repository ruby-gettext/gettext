module GetText
  class ParseError < StandardError
  end

  # Contains data related to the expression or sentence that 
  # is to be translated (translation target).
  # Implements a sort of state machine to assist the parser.
  class TranslationTarget
    attr_accessor :type, :msgid, :occurrences # obligatory attributes
    attr_accessor :plural, :msgctxt, :extracted_comment # optional attributes

    def initialize(new_type)
      @type = new_type
      @occurrences = Array.new
      @param_number = 0
    end

    # Supports parsing by setting attributes by and by.
    def set_current_attribute(str)
      case @param_number 
      when 0
        set_string_value :msgid, str
      when 1
        case type
        when :plural
          set_string_value :plural, str
        when :msgctxt, :msgctxt_plural
          set_string_value :msgctxt, str
        else
          raise ParseError, 'no more string parameters expected'
        end
      when 2
        if :msgctxt_plural
          set_string_value plural, str
        else
          raise ParseError, 'no more string parameters expected'
        end
      end
    end

    def advance_to_next_attribute
      @param_number += 1
    end

    # Support for extracted comments. Explanation s.
    # http://www.gnu.org/software/gettext/manual/gettext.html#Names
    def add_extracted_comment(new_comment)
      @extracted_comment = @extracted_comment.to_s + new_comment
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
      return self if other.nil?
      raise ParseError, "Translation targets do not match: \n" \
      "  self: #{self.inspect}\n  other: '#{other.inspect}'" unless matches?(other)
      if other.plural && !self.plural
        res = other
        res.occurrences.concat self.occurrences
      else
        res = self
        res.occurrences.concat other.occurrences
      end
      res
    end

    private

    # sets or extends the value of a translation target params like msgid,
    # msgctxt etc.
    #   param is symbol with the name of param
    #   value - new value
    def set_string_value(param, value)
      send "#{param}=", (send(param) || '') + value.gsub(/\n/, '\n')
    end
  end

end
