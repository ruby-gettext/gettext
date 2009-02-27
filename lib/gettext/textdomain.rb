=begin
  textdomain.rb - GetText::Textdomain

  Copyright (C) 2001-2009  Masao Mutoh
  Copyright (C) 2001-2003  Masahiro Sakai

      Masahiro Sakai    <s01397ms@sfc.keio.ac.jp>
      Masao Mutoh       <mutoh@highway.ne.jp>

  You may redistribute it and/or modify it under the same
  license terms as Ruby.

  $Id$
=end

require 'gettext/core_ext/string'
require 'gettext/mofile'
require 'rbconfig'

module GetText
  # GetText::TextDomain class manages mo-files of a textdomain.
  #
  # Usually, you don't need to use this class directly.
  #
  # Notice: This class is unstable. APIs will be changed.
  class TextDomain

    attr_reader :output_charset
    attr_reader :locale_paths
    attr_reader :mofiles
    attr_reader :name

    @@cached = ! $DEBUG
    # Cache the mo-file or not.
    # Default is true. If $DEBUG is set then false.
    def self.cached?
      @@cached
    end

    # Set to cache the mo-file or not.
    # * val: true if cached, otherwise false.
    def self.cached=(val)
      @@cached = val
    end
    # The default locale paths.
    CONFIG_PREFIX = Config::CONFIG['prefix'].gsub(/\/local/, "")
    DEFAULT_LOCALE_PATHS = [
      "#{Config::CONFIG['datadir']}/locale/%{lang}/LC_MESSAGES/%{name}.mo",
      "#{Config::CONFIG['datadir'].gsub(/\/local/, "")}/locale/%{lang}/LC_MESSAGES/%{name}.mo",
      "#{CONFIG_PREFIX}/share/locale/%{lang}/LC_MESSAGES/%{name}.mo",
      "#{CONFIG_PREFIX}/local/share/locale/%{lang}/LC_MESSAGES/%{name}.mo"
    ].uniq

    # Add default locale path. Usually you should use GetText.add_default_locale_path instead.
    # * path: a new locale path. (e.g.) "/usr/share/locale/%{lang}/LC_MESSAGES/%{name}.mo"
    #   ('locale' => "ja_JP", 'name' => "textdomain")
    # * Returns: the new DEFAULT_LOCALE_PATHS
    def self.add_default_locale_path(path)
      DEFAULT_LOCALE_PATHS.unshift(path)
    end

    # Creates a new GetText::TextDomain.
    # * name: the textdomain name.
    # * topdir: the locale path ("%{topdir}/%{lang}/LC_MESSAGES/%{name}.mo") or nil.
    # * output_charset: output charset.
    # * Returns: a newly created GetText::TextDomain object.
    def initialize(name, topdir = nil, output_charset = nil)
      @name, @topdir, @output_charset = name, topdir, output_charset

      @locale_paths = []
      if ENV["GETTEXT_PATH"]
        ENV["GETTEXT_PATH"].split(/,/).each {|i| 
          @locale_paths += ["#{i}/%{lang}/LC_MESSAGES/%{name}.mo", "#{i}/%{lang}/%{name}.mo"]
        }
      elsif @topdir
        @locale_paths += ["#{@topdir}/%{lang}/LC_MESSAGES/%{name}.mo", "#{@topdir}/%{lang}/%{name}.mo"]
      end

      unless @topdir
        @locale_paths += DEFAULT_LOCALE_PATHS
    
        if defined? Gem
          $:.each do |path|
            if /(.*)\/lib$/ =~ path
              @locale_paths += [
                                "#{$1}/data/locale/%{lang}/LC_MESSAGES/%{name}.mo", 
                                "#{$1}/data/locale/%{lang}/%{name}.mo", 
                                "#{$1}/locale/%{lang}/%{name}.mo"]
            end
          end
        end
      end
   
      @mofiles = {}
    end
    
    # Translates the translated string.
    # * lang: Locale::Tag::Simple's subclass.
    # * msgid: the original message.
    # * Returns: the translated string or nil.
    def translate_singluar_message(lang, msgid)
      return "" if msgid == "" or msgid.nil?

      lang_key = lang.to_s

      mofile = nil
      if self.class.cached?
        mofile = @mofiles[lang_key]
      end
      unless mofile
        mofile = load_mo(lang)
      end
     
      if (! mofile) or (mofile ==:empty)
        return nil
      end

      msgstr = mofile[msgid]
      if msgstr and (msgstr.size > 0)
        msgstr
      elsif msgid.include?("\000")
        # Check "aaa\000bbb" and show warning but return the singluar part.
        ret = nil
        msgid_single = msgid.split("\000")[0]
        mofile.each{|key, val| 
          if key =~ /^#{Regexp.quote(msgid_single)}\000/
            # Usually, this is not caused to make po-files from rgettext.
            warn %Q[Warning: n_("#{msgid_single}", "#{msgid.split("\000")[1]}") and n_("#{key.gsub(/\000/, '", "')}") are duplicated.]
            ret = val
            break
          end
        }
        ret
      else
        ret = nil
        mofile.each{|key, val| 
          if key =~ /^#{Regexp.quote(msgid)}\000/
            ret = val.split("\000")[0]
            break
          end
        }
        ret
      end
    end

    # Translates the translated string.
    # * lang: Locale::Tag::Simple's subclass.
    # * msgid: the original message.
    # * msgid_plural: the original message(plural).
    # * Returns: the translated string as an Array ([[msgstr1, msgstr2, ...], cond]) or nil.
    def translate_plural_message(lang, msgid, msgid_plural)   #:nodoc:
      key = msgid + "\000" + msgid_plural
      msg = translate_singluar_message(lang, key)
      ret = nil
      if ! msg
        ret = nil
      elsif msg.include?("\000")
        # [[msgstr[0], msgstr[1], msgstr[2],...], cond]
        mofile = @mofiles[lang.to_posix.to_s]
        cond = (mofile and mofile != :empty) ? mofile.plural : nil
        cond ||= "n != 1"
        ret = [msg.split("\000"), cond]
      else
        ret = [[msg], "0"]
      end
      ret
    end

    # Clear cached mofiles.
    def clear
      @mofiles = {}
    end

    # Set output_charset.
    # * charset: output charset.
    def output_charset=(charset)
      @output_charset = charset
      clear
    end

    private
    # Load a mo-file from the file.
    # lang is the subclass of Locale::Tag::Simple.
    def load_mo(lang)
      lang = lang.to_posix unless lang.kind_of? Locale::Tag::Posix
      lang_key = lang.to_s

      mofile = @mofiles[lang_key]
      if mofile
        if mofile == :empty
          return :empty
        elsif ! self.class.cached?
          mofile.update!
        end
        return mofile
      end

      search_files = []

      lang_candidates = lang.to_posix.candidates
      @locale_paths.each do |dir|
        lang_candidates.each{|tag|
          fname = dir % {:lang => tag, :name => @name}
          if $DEBUG
            search_files << fname unless search_files.include?(fname)
          end
          if File.exist?(fname)
            warn "GetText::TextDomain#load_mo: mo-file is #{fname}" if $DEBUG

            charset = @output_charset || lang.charset || Locale.charset || "UTF-8"
            mofile = MOFile.open(fname, charset)
            break
          end
        }
        break if mofile
      end

      if mofile
        @mofiles[lang_key] = mofile
      else
        @mofiles[lang_key] = :empty
        if $DEBUG
          warn "MO file is not found in"
          search_files.each do |v|
            warn "  #{v}"
          end
        end
      end
      mofile
    end

  end
end
