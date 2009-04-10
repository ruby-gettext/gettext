=begin
  gettext/textdomain_group - GetText::TextDomainGroup class

  Copyright (C) 2009  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby.

=end

module GetText

  class TextDomainGroup
    attr_reader :textdomains, :supported_language_tags
    
    def initialize(supported_language_tags)
      @textdomains = []
      @supported_language_tags = supported_language_tags
    end

    def add(textdomain)
      @textdomains.unshift(textdomain) unless @textdomains.include? textdomain
    end
  end
end
