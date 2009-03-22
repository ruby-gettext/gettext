=begin
  locale_path.rb - GetText::LocalePath

  Copyright (C) 2001-2009  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby.

=end

require 'rbconfig'

module GetText
  # Treats locale-path for mo-files.
  class LocalePath
    # The default locale paths.
    CONFIG_PREFIX = Config::CONFIG['prefix'].gsub(/\/local/, "")
    DEFAULT_RULES = [
                     "#{Config::CONFIG['datadir']}/locale/%{lang}/LC_MESSAGES/%{name}.mo",
                     "#{Config::CONFIG['datadir'].gsub(/\/local/, "")}/locale/%{lang}/LC_MESSAGES/%{name}.mo",
                     "#{CONFIG_PREFIX}/share/locale/%{lang}/LC_MESSAGES/%{name}.mo",
                     "#{CONFIG_PREFIX}/local/share/locale/%{lang}/LC_MESSAGES/%{name}.mo"
                    ].uniq
    
    # Add default locale path. Usually you should use GetText.add_default_locale_path instead.
    # * path: a new locale path. (e.g.) "/usr/share/locale/%{lang}/LC_MESSAGES/%{name}.mo"
    #   ('locale' => "ja_JP", 'name' => "textdomain")
    # * Returns: the new DEFAULT_LOCALE_PATHS
    def self.add_default_rule(path)
      DEFAULT_RULES.unshift(path)
    end

    @@default_path_rules = []

    # Returns path rules as an Array. 
    # (e.g.) ["/usr/share/locale/%{lang}/LC_MESSAGES/%{name}.mo", ...] 
    def self.default_path_rules 
      return @@default_path_rules.dup if @@default_path_rules.size > 0

      if ENV["GETTEXT_PATH"]
        ENV["GETTEXT_PATH"].split(/,/).each {|i| 
          @@default_path_rules = ["#{i}/%{lang}/LC_MESSAGES/%{name}.mo", "#{i}/%{lang}/%{name}.mo"]
        }
      end

      @@default_path_rules += DEFAULT_RULES
      
      $LOAD_PATH.each {|path|
        if /(.*)\/lib$/ =~ path
          @@default_path_rules += [
                           "#{$1}/data/locale/%{lang}/LC_MESSAGES/%{name}.mo", 
                           "#{$1}/data/locale/%{lang}/%{name}.mo", 
                           "#{$1}/locale/%{lang}/%{name}.mo"]
        end
      }
      @@default_path_rules.dup
    end

    # Clear path_rules for testing.
    def self.clear
      @@default_path_rules = nil
    end

    attr_reader :locale_paths

    # Creates a new GetText::TextDomain.
    # * name: the textdomain name.
    # * topdir: the locale path ("%{topdir}/%{lang}/LC_MESSAGES/%{name}.mo") or nil.
    def initialize(name, topdir = nil)
      @name = name
      
      if topdir
        @locale_paths = ["#{topdir}/%{lang}/LC_MESSAGES/%{name}.mo", "#{topdir}/%{lang}/%{name}.mo"]
      else
        @locale_paths = self.class.default_path_rules
      end
      @locale_paths.map! {|v| v % {:name => name} }
    end

    # Gets the current path.
    # * lang: a Locale::Tag.
    def current_path(lang)
      lang_candidates = lang.to_posix.candidates
      search_files = []

      @locale_paths.each {|path|
        lang_candidates.each{|tag|
          fname = path % {:lang => tag}
          if $DEBUG
            search_files << fname unless search_files.include?(fname)
          end
          if File.exist?(fname)
            warn "GetText::TextDomain#load_mo: mo-file is #{fname}" if $DEBUG
            return fname
          end
        }
      }
      if $DEBUG
        warn "MO file is not found in"
        search_files.each do |v|
          warn "  #{v}"
        end
      end
      nil
    end
  end
end
