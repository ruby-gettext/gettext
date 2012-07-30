# encoding: utf-8

=begin
  rmsginit.rb - Initialize .pot with metadata and create .po

  Copyright (C) 2012 Haruka Yoshihara

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.
=end

require 'gettext'
require 'locale/info'
require 'rbconfig'
require 'optparse'

module GetText
  module RMsgInit
    extend GetText
    extend self

    bindtextdomain "rgettext"

    def run(input_file=nil, output_file=nil, locale=nil)
      options = check_options(input_file, output_file, locale)

      input_file = options[:input_file]
      output_file = options[:output_file]
      locale = options[:locale]

      pot_contents = File.read(input_file)

      pot_contents = replace_description(pot_contents, locale)
      pot_contents = replace_translators(pot_contents)
      pot_contents = replace_date(pot_contents)
      pot_contents = replace_language(pot_contents, locale)
      pot_contents = replace_plural_forms(pot_contents, locale)
      pot_contents = pot_contents.sub(/#, fuzzy\n/, "")

      File.open(output_file, "w") do |f|
        f.puts(pot_contents)
      end

      self
    end

    VERSION = GetText::VERSION
    DATE = "2012/07/30"

    def parse_arguments #:nodoc:
      input_file = nil
      output_file = nil
      locale = nil

      parser = OptionParser.new
      parser.banner = "Usage: #{$0} [OPTION]"
      options_description =
_(<<EOD
Initialize a .pot file with user's environment and input and create a .po
file from an initialized .pot file.
A .pot file is specified as input_file. If input_file is not
specified, a .pot file existing current directory is used. A .po file is
created from initialized input_file as output_file. if output_file
isn't specified, output_file is "locale.po". If locale is not
specified, 'ja' is used as locale.
EOD
)
      parser.separator(options_description)
      parser.separator("")
      parser.separator(_("Specific options:"))

      parser.on("-i",
                "--input=FILE", _("read input from specified file")) do |input|
        if File.exist?(input)
          input_file = input
        else
          raise(_("file #{input} does not exist."))
        end
      end

      parser.on("-o",
                "--output=FILE", _("write output to specified file")) do |output|
        unless File.exist?(output)
          output_file = output
        else
          raise(_("file #{output} has already existed."))
        end
      end

      parser.on("-l",
                "--locale=LOCALE", _("locale used with .po file")) do |loc|
        locale = loc
      end

      parser.on("-h",
                "--help", _("dispray this help and exit")) do
        puts parser.help
        exit(true)
      end

      parser.on_tail("--version", _("display version information and exit")) do
        puts "#{$0} #{VERSION} (#{DATE})"
        ruby_bin_dir = ::RbConfig::CONFIG["bindir"]
        ruby_install_name = ::RbConfig::CONFIG["RUBY_INSTALL_NAME"]
        ruby_description = "#{File.join(ruby_bin_dir, ruby_install_name)} " +
          "#{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) [#{RUBY_PLATFORM}]"
        puts(ruby_description)
        exit(true)
      end

      parser.parse!(ARGV)

      [input_file, output_file, locale]
    end

    def check_options(input_file, output_file, locale)
      options = {}

      options[:input_file] ||= input_file
      if options[:input_file].nil?
        default_pot_file = Dir.glob("./*.pot").first
        if default_pot_file.nil?
          message = _("rmsginit: input file is not specified, " +
            "but no .pot file exists in current directory.")
          raise(message)
        else
          options[:input_file] = default_pot_file
        end
      end

      options[:locale] = locale || "ja"

      options[:output_file] ||= output_file
      if options[:output_file].nil? or File.exist?(options[:output_file])
        default_po_file = "#{options[:locale]}.po"
        if File.exist?(default_po_file)
          raise(_("file #{default_po_file} has existed."))
        else
          options[:output_file] = default_po_file
        end
      end
      options
    end

    DESCRIPTION_TITLE = /SOME DESCRIPTIVE TITLE\./

    def replace_description(pot, locale)
      language_name = Locale::Info.get_language(locale.to_s).name
      description = "#{language_name} translations for PACKAGE package."

      pot.sub(DESCRIPTION_TITLE, description)
    end

    FIRST_AUTHOR_KEY = /(#) FIRST AUTHOR/
    LAST_TRANSLATOR_KEY = /(Last-Translator:) FULL NAME/
    EMAIL_KEY = /EMAIL@ADDRESS/

    def replace_translators(pot) #:nodoc:
      fullname, mail = get_translator_metadata
      pot = pot.sub(FIRST_AUTHOR_KEY, "\\1 #{fullname}")
      pot = pot.sub(LAST_TRANSLATOR_KEY, "\\1 #{fullname}")
      pot.gsub(EMAIL_KEY, mail)
    end

    def get_translator_metadata
      logname = ENV["LOGNAME"] || `whoami`
      if /Name: (.+)/ =~ `finger #{logname}`
        fullname = $1
      else
        fullname = logname
      end

      puts "Please enter your email address."
      mail = STDIN.gets.chomp
      if mail.empty?
        hostname = `hostname`.chomp
        mail = "#{logname}@#{hostname}"
      end

      [fullname, mail]
    end

    POT_REVISION_DATE_KEY = /(PO-Revision-Date:).+/
    YEAR_KEY = /(\s*#.+) YEAR/

    def replace_date(pot) #:nodoc:
      date = Time.now
      revision_date = date.strftime("%Y-%m-%d %H:%M%z")

      pot = pot.sub(POT_REVISION_DATE_KEY, "\\1 #{revision_date}\\n\"")
      pot.gsub(YEAR_KEY, "\\1 #{date.year.to_s}")
    end

    LANGUAGE_KEY = /(Language:).+/
    LANGUAGE_TEAM_KEY = /(Language-Team:).+/

    def replace_language(pot, locale) #:nodoc:
      pot = pot.sub(LANGUAGE_KEY, "\\1 #{locale}\\n\"")

      language_name = Locale::Info.get_language(locale.to_s).name
      pot.sub(LANGUAGE_TEAM_KEY, "\\1 #{language_name}\\n\"")
    end

    def replace_plural_forms(pot, locale)
      nplural, plural_expression = plural_forms(locale)
      pot.sub(/(Plural-Forms: nplurals=)INTEGER;( plural=)EXPRESSION;/,
          "\\1#{nplural};\\2#{plural_expression};")
    end

    def plural_forms(locale)
      case locale.to_s
      when "ja", "vi", "ko"
        nplural = "1"
        plural_expression = "0"
      when "en", "de", "nl", "sv", "da", "no", "fo", "es", "pt",
        "it", "bg", "el", "fi", "et", "he", "eo", "hu", "tr"
        nplural = "2"
        plural_expression = "n != 1"
      when "pt_BR", "fr"
        nplural = "2"
        plural_expression = "n>1"
      when "lv"
        nplural = "3"
        plural_expression = "n%10==1 && n%100!=11 ? 0 : n != 0 ? 1 : 2"
      when "ga"
        nplural = "3"
        plural_expression = "n==1 ? 0 : n==2 ? 1 : 2"
      when "ro"
        nplural = "3"
        plural_expression = "n==1 ? 0 : " +
          "(n==0 || (n%100 > 0 && n%100 < 20)) ? 1 : 2"
      when "lt"
        nplural = "3"
        plural_expression = "n%10==1 && n%100!=11 ? 0 : " +
          "n%10>=2 && (n%100<10 || n%100>=20) ? 1 : 2"
      when "ru", "uk", "sr", "hr"
        nplural = "3"
        plural_expression = "n%10==1 && n%100!=11 ? 0 : n%10>=2 && " +
          "n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2"
      when "cs", "sk"
        nplural = "3"
        plural_expression = "(n==1) ? 0 : (n>=2 && n<=4) ? 1 : 2"
      when "pl"
        nplural = "3"
        plural_expression = "n==1 ? 0 : n%10>=2 && " +
          "n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2"
      when "sl"
        nplural = "4"
        plural_expression = "n%100==1 ? 0 : n%100==2 ? 1 : n%100==3 " +
          "|| n%100==4 ? 2 : 3"
      else
        nplural = nil
        plural_expression = nil
      end
      [nplural, plural_expression]
    end
  end
end

module GetText
  # Initialize a .pot file with user's environment and input and
  # create a .po file from an initialized .pot file.
  # A .pot file is specified as input_file. If input_file is not
  # specified, a .pot file existing current directory is used.
  # A .po file is created from initialized input_file as output_file.
  # if output_file isn't specified, output_file is "locale.po".
  # If locale is not specified, 'ja' is used as locale.
  def rmsginit
    GetText::RMsgInit.run(*GetText::RMsgInit.parse_arguments)
    self
  end

  module_function :rmsginit
end

if $0 == __FILE__ then
  require 'pp'

  GetText.rmsginit
end
