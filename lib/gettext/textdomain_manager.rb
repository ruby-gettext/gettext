require 'gettext/textdomain'
require 'gettext/class_info'
require 'locale/util/memoizable'

module GetText
  class TextDomainManager
    include Locale::Util::Memoizable

    @@cached  = ! $DEBUG
    @@textdomain_pool = {}
    @@textdomain_manager_pool = {}

    @@output_charset = nil
    @@gettext_classes = []

    # Find textdomain by name
    def self.textdomain_pool(domainname)
      @@textdomain_pool[domainname]
    end

    # create or find a textdomain-manager for an given object/class
    def self.get(obj)
      klass = ClassInfo.normalize_class(obj)
      manager = @@textdomain_manager_pool[klass]
      return manager if manager
      @@textdomain_manager_pool[klass] = TextDomainManager.new
    end

    # Set the value whether cache messages or not. 
    # true to cache messages, otherwise false.
    #
    # Default is true. If $DEBUG is false, messages are not checked even if
    # this value is true.
    def self.cached=(val)
      @@cached = val
      @@textdomain_pool.each do |key, textdomain|
        textdomain.cached = val
      end
    end
    
    # Return the cached value.
    def self.cached?
      @@cached
    end

    # Gets the output charset.
    def self.output_charset
      @@output_charset 
    end

    # Sets the output charset.The program can have a output charset.
    def self.output_charset=(charset)
      @@output_charset = charset
      @@textdomain_pool.each do |key, textdomain|
        textdomain.charset = charset
      end
    end
   
    # bind textdomain to the class.
    def self.bind_to(klass, domainname, options = {})
      warn "Bind the domain '#{domainname}' to '#{klass}'. " if $DEBUG

      charset = options[:output_charset] || self.output_charset
      textdomain = create_or_find_textdomain(domainname,options[:path],charset)

      target_klass = ClassInfo.normalize_class(klass)
      get(target_klass).add(textdomain, options[:supported_language_tags])
      add_to_gettext_classes(target_klass)

      textdomain
    end
 
    #
    # Instance methods
    #

    # Returns the textdoman in the instance.
    attr_reader :textdomains, :supported_language_tags
  
    def initialize
      @textdomains = []
      @supported_language_tags = nil
    end

    def add(textdomain, supported_language_tags)
      @textdomains.unshift(textdomain) unless @textdomains.include? textdomain
      @supported_language_tags = supported_language_tags if supported_language_tags
    end

    # Translates msgid, but if there are no localized text, 
    # it returns a last part of msgid separeted "div" or whole of the msgid with no "div".
    #
    # * msgid: the message id.
    # * div: separator or nil.
    # * Returns: the localized text by msgid. If there are no localized text, 
    #   it returns a last part of msgid separeted "div".
    def translate_singluar_message(klass, msgid, div = '|')
      lang = Locale.candidates(:supported_language_tags => @supported_language_tags, 
                               :type => :posix)[0]
      translate_singluar_message_to(lang, klass, msgid, div)
    end

    def translate_singluar_message_to(lang, klass, msgid, div = '|') #:nodoc:
      msg = nil
      # Find messages from related classes.
      ClassInfo.related_classes(klass, @@gettext_classes).each do |target|
        msg = nil
        self.class.get(target).textdomains.each do |textdomain|
          msg = textdomain.translate_singluar_message(lang, msgid)
          break if msg
        end
        break if msg
      end
      
      # If not found, return msgid.
      msg ||= msgid
      if div and msg == msgid
        if index = msg.rindex(div)
          msg = msg[(index + 1)..-1]
        end
      end
      msg
    end
    memoize :translate_singluar_message_to

    # This function is similar to the get_singluar_message function 
    # as it finds the message catalogs in the same way. 
    # But it takes two extra arguments for plural form.
    # The msgid parameter must contain the singular form of the string to be converted. 
    # It is also used as the key for the search in the catalog. 
    # The msgid_plural parameter is the plural form. 
    # The parameter n is used to determine the plural form. 
    # If no message catalog is found msgid1 is returned if n == 1, otherwise msgid2. 
    # And if msgid includes "div", it returns a last part of msgid separeted "div".
    #
    # * msgid: the singular form with "div". (e.g. "Special|An apple", "An apple")
    # * msgid_plural: the plural form. (e.g. "%{num} Apples")
    # * n: a number used to determine the plural form.
    # * div: the separator. Default is "|".
    # * Returns: the localized text which key is msgid_plural if n is plural(follow plural-rule) or msgid.
    #   "plural-rule" is defined in po-file.
    #
    # or
    #
    # * [msgid, msgid_plural] : msgid and msgid_plural an Array
    # * n: a number used to determine the plural form.
    # * div: the separator. Default is "|".
    def translate_plural_message(klass, arg1, arg2, arg3 = "|", arg4 = "|")
      lang = Locale.candidates(:supported_language_tags => @supported_language_tags,
                               :type => :posix)[0]
      # parse arguments
      if arg1.kind_of?(Array)
        msgid = arg1[0]
        msgid_plural = arg1[1]
        n = arg2
        if arg3 and arg3.kind_of? Numeric
          raise ArgumentError, _("3rd parmeter is wrong: value = %{number}") % {:number => arg3}
        end
        div = arg3
      else
        msgid = arg1
        msgid_plural = arg2
        n = arg3
        div = arg4
      end

      msgs = nil
      
      # Find messages from related classes.
      ClassInfo.related_classes(klass, @@gettext_classes).each do |target|
        msgs = nil
        self.class.get(target).textdomains.each do |textdomain|
          msgs = textdomain.translate_plural_message(lang, msgid, msgid_plural)
          break if msgs
        end
        break if msgs
      end
      
      # If not found, return msgid.
      msgs = [[msgid, msgid_plural], "n != 1"] unless msgs

      msgstrs = msgs[0]
      if div and msgstrs[0] == msgid and index = msgstrs[0].rindex(div)
        msgstrs[0] = msgstrs[0][(index + 1)..-1]
      end

      # Return the singular or plural message.
      plural = eval(msgs[1])
      return msgstrs[plural] if plural.kind_of?(Numeric)
      return plural ? msgstrs[1] : msgstrs[0]
    end
    
    # for testing.
    def self.clear_all_textdomains
      @@textdomain_pool = {}
      @@textdomain_manager_pool = {}
      @@gettext_classes = []
    end
    
  private

    def self.add_to_gettext_classes(klass)
      @@gettext_classes << klass unless @@gettext_classes.include? klass
    end

    def self.create_or_find_textdomain(name, path, charset)#:nodoc:
      textdomain = @@textdomain_pool[name]
      return textdomain if textdomain

      @@textdomain_pool[name] = TextDomain.new(name, path, charset)
    end
  end
end
