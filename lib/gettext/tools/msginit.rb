# -*- coding: utf-8 -*-
#
# Copyright (C) 2012  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2012  Kouhei Sutou <kou@clear-code.com>
#
# License: Ruby's or LGPL
#
# This library is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require "gettext"
require "locale/info"
require "optparse"

module GetText
  module Tools
    class MsgInit
      class Error < StandardError
      end

      class ArgumentError < Error
      end

      class ValidationError < Error
      end

      class << self
        # Create a new .po file from initializing .pot file with user's
        # environment and input.
        # @param [Array<String>] arguments arguments for rmsginit.
        # @return [void]
        def run(*arguments)
          new.run(*arguments)
        end
      end

      include GetText

      bindtextdomain("rgettext")

      def initialize #:nodoc:
        @input_file = nil
        @output_file = nil
        @locale = nil
        @language = nil
      end

      # Create .po file from .pot file, user's inputs and metadata.
      # @param [Array] arguments the list of arguments for rmsginit
      def run(*arguments)
        parse_arguments(*arguments)
        validate

        parser = PoParser.new
        parser.ignore_fuzzy = false
        pot = parser.parse_file(@input_file,
                                GetText::Tools::MsgMerge::PoData.new)
        po = replace_pot_header(pot)

        File.open(@output_file, "w") do |f|
          f.puts(po.generate_po)
        end
      end

      private
      def validate
        if @input_file.nil?
          @input_file = Dir.glob("./*.pot").first
          if @input_file.nil?
            raise(ValidationError,
                  _(".pot file does not exist in the current directory."))
          end
        else
          unless File.exist?(@input_file)
            raise(ValidationError,
                  _("file #{@input_file} does not exist."))
          end
        end

        if @locale.nil?
          language_tag = Locale.current
        else
          language_tag = Locale::Tag.parse(@locale)
        end

        unless valid_locale?(language_tag)
          raise(ValidationError,
                _("Locale '#{language_tag}' is invalid. " +
                    "Please check if your specified locale is usable."))
        end
        @locale = language_tag.to_simple.to_s
        @language = language_tag.language

        @output_file ||= "#{@locale}.po"
        if File.exist?(@output_file)
          raise(ValidationError,
                _("file #{@output_file} has already existed."))
        end
      end

      def valid_locale?(language_tag)
        return false if language_tag.instance_of?(Locale::Tag::Irregular)

        Locale::Info.language_code?(language_tag.language)
      end

      VERSION = GetText::VERSION

      def parse_arguments(*arguments) #:nodoc:
        parser = OptionParser.new
        description = _("Create a new .po file from initializing .pot " +
                          "file with user's environment and input.")
        parser.separator(description)
        parser.separator("")
        parser.separator(_("Specific options:"))

        input_description = _("Use INPUT as a .pot file. If INPUT is not " +
                                "specified, INPUT is a .pot file existing " +
                                "the current directory.")
        parser.on("-i", "--input=FILE", input_description) do |input|
          @input_file = input
        end

        output_description = _("Use OUTPUT as a created .po file. If OUTPUT " +
                                 "is not specified, OUTPUT depend on LOCALE " +
                                 "or the current locale on your environment.")
        parser.on("-o", "--output=OUTPUT", output_description) do |output|
          @output_file = output
        end

        locale_description = _("Use LOCALE as target locale. If LOCALE is " +
                                 "not specified, LOCALE is the current " +
                                 "locale on your environment.")
        parser.on("-l", "--locale=LOCALE", locale_description) do |loc|
          @locale = loc
        end

        parser.on("-h", "--help", _("Dispray this help and exit")) do
          puts(parser.help)
          exit(true)
        end

        version_description = _("Display version and exit")
        parser.on_tail("-v", "--version", version_description) do
          puts(VERSION)
          exit(true)
        end

        begin
          parser.parse!(arguments)
        rescue OptionParser::ParseError
          raise(ArgumentError, $!.message)
        end
      end

      DESCRIPTION_TITLE = /^(\s*#\s*) SOME DESCRIPTIVE TITLE\.$/

      def replace_pot_header(pot) #:nodoc:
        header = pot[""]
        comment = pot.comment("")

        comment = replace_description(header, comment)
        header, comment = replace_translators(header, comment)
        header, comment = replace_date(header, comment)
        header = replace_language(header)
        header = replace_plural_forms(header)
        comment = comment.gsub(/#, fuzzy/, "")

        pot[""] = header.chomp
        pot.set_comment("", comment)
        pot
      end

      def replace_description(header, comment) #:nodoc:
        language_name = Locale::Info.get_language(@language).name
        package_name = ""
        header.gsub(/Project-Id-Version: (.+?) .+/) do
          package_name = $1
        end
        description = "#{language_name} translations " +
                        "for #{package_name} package."
        comment.gsub(DESCRIPTION_TITLE, "\\1 #{description}")
      end

      EMAIL = "EMAIL@ADDRESS"
      YEAR_KEY = /^(\s*#\s* FIRST AUTHOR <#{EMAIL}>,) YEAR\.$/
      FIRST_AUTHOR_KEY = /^(\s*#\s*) FIRST AUTHOR <#{EMAIL}>, (\d+\.)$/
      LAST_TRANSLATOR_KEY = /^(Last-Translator:) FULL NAME <#{EMAIL}>$/

      def replace_translators(header, comment) #:nodoc:
        full_name = translator_full_name
        mail = translator_mail
        translator = "#{full_name} <#{mail}>"
        year = Time.now.year

        comment = comment.gsub(YEAR_KEY, "\\1 #{year}.")
        if not full_name.empty? and not mail.empty?
          comment = comment.gsub(FIRST_AUTHOR_KEY, "\\1 #{translator}, \\2")
          header = header.gsub(LAST_TRANSLATOR_KEY, "\\1 #{translator}")
        end
        [header, comment]
      end

      def translator_full_name
        read_translator_full_name
      end

      def read_translator_full_name #:nodoc:
        prompt(_("Please enter your full name"), guess_full_name)
      end

      def guess_full_name
        ENV["USERNAME"]
      end

      def translator_mail
        read_translator_mail
      end

      def read_translator_mail #:nodoc:
        prompt(_("Please enter your email address"), guess_mail)
      end

      def guess_mail
        ENV["EMAIL"]
      end

      def prompt(message, default)
        print(message)
        print(" [#{default}]") if default
        print(": ")

        user_input = $stdin.gets.chomp
        if user_input.empty?
          default
        else
          user_input
        end
      end

      POT_REVISION_DATE_KEY = /^("PO-Revision-Date:).+\\n"$/
      COPYRIGHT_KEY = /(\s*#\s* Copyright \(C\)) YEAR (THE PACKAGE'S COPYRIGHT HOLDER)$/

      def replace_date(header, comment) #:nodoc:
        date = Time.now
        revision_date = date.strftime("%Y-%m-%d %H:%M%z")

        header = header.gsub(POT_REVISION_DATE_KEY, "\\1 #{revision_date}\\n\"")
        comment = comment.gsub(COPYRIGHT_KEY, "\\1 #{date.year} \\2")

        [header, comment]
      end

      LANGUAGE_KEY = /^(Language:).+/
      LANGUAGE_TEAM_KEY = /^(Language-Team:).+/

      def replace_language(header) #:nodoc:
        language_name = Locale::Info.get_language(@language).name
        header = header.gsub(LANGUAGE_KEY, "\\1 #{@locale}")
        header.gsub(LANGUAGE_TEAM_KEY, "\\1 #{language_name}")
      end

      PLURAL_FORMS =
        /^(Plural-Forms:) nplurals=INTEGER; plural=EXPRESSION;$/

      def replace_plural_forms(header) #:nodoc:
        header.gsub(PLURAL_FORMS, "\\1 #{plural_forms(@language)}")
      end

      def plural_forms(language) #:nodoc:
        case language
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

        "nplurals=#{nplural}; plural=#{plural_expression};"
      end
    end
  end
end
