#!/usr/bin/ruby
=begin
  parser/ruby.rb - parser for ruby script

  Copyright (C) 2003-2005  Masao Mutoh
  Copyright (C) 2005       speakillof
  Copyright (C) 2001,2002  Yasushi Shoji, Masao Mutoh
 
  You may redistribute it and/or modify it under the same
  license terms as Ruby.

  $Id: ruby.rb,v 1.13 2008/12/01 14:30:30 mutoh Exp $
=end

require 'irb/ruby-lex.rb'
require 'stringio'
require 'translation_target.rb'

class RubyLexX < RubyLex  # :nodoc: all
  # Parser#parse resemlbes RubyLex#lex
  def parse
    until (  (tk = token).kind_of?(RubyToken::TkEND_OF_SCRIPT) && !@continue or tk.nil?  )
      s = get_readed
      if RubyToken::TkSTRING === tk
        def tk.value
          @value 
        end
        
        def tk.value=(s)
          @value = s
        end
        
        if @here_header
          s = s.sub(/\A.*?\n/, '').sub(/^.*\n\Z/, '')
        else
          begin
            s = eval(s)
          rescue Exception
            # Do nothing.
          end
        end
        
        tk.value = s
      end
      
      if $DEBUG
        if tk.is_a? TkSTRING
          $stderr.puts("#{tk}: #{tk.value}")
        elsif tk.is_a? TkIDENTIFIER
          $stderr.puts("#{tk}: #{tk.name}")
        else
          $stderr.puts(tk)
        end
      end
      
      yield tk
    end
    return nil
  end

  RubyToken.def_token :TkCOMMENT_WITH_CONTENT, TkVal

  def identify_comment
    @ltype = "#"

    while ch = getc
      if ch == "\n"
        @ltype = nil
        ungetc
        break
      end
    end
    return Token(TkCOMMENT_WITH_CONTENT, get_readed)
  end

end

module GetText
  module RubyParser
    extend self
    
    ID = ['gettext', '_', 'N_', 'sgettext', 's_']
    PLURAL_ID = ['ngettext', 'n_', 'Nn_', 'ns_', 'nsgettext']
    MSGCTXT_ID = ['pgettext', 'p_']
    MSGCTXT_PLURAL_ID = ['npgettext', 'np_']

    def parse(file, targets = [])  # :nodoc:
      lines = IO.readlines(file)
      parse_lines(file, lines, targets)
    end

    def parse_lines(file_name, lines, targets)  # :nodoc:
      file = StringIO.new(lines.join + "\n")
      rl = RubyLexX.new
      rl.set_input(file)
      rl.skip_space = true
      #rl.readed_auto_clean_up = true

      target = nil
      msgid = nil
      line_no = nil
      last_translator_comment = ''
      reset_translator_comment = false
      rl.parse do |tk|
        begin
          case tk
          when RubyToken::TkIDENTIFIER, RubyToken::TkCONSTANT
            if ID.include?(tk.name)
              target = :normal
            elsif PLURAL_ID.include?(tk.name)
              target = :plural
            elsif MSGCTXT_ID.include?(tk.name)
              target = :msgctxt
            elsif MSGCTXT_PLURAL_ID.include?(tk.name)
              target = :msgctxt_plural
            else
              target = nil
            end
            line_no = tk.line_no.to_s
          when RubyToken::TkSTRING
            if target
              if msgid
                msgid += tk.value
              else
                msgid = tk.value
              end
            end
          when RubyToken::TkPLUS, RubyToken::TkNL
            #do nothing
          when RubyToken::TkCOMMA
            if msgid
              case target
              when :plural
                msgid += "\000"
                target = :normal
              when :msgctxt
                msgid += "\004"
                target = :normal
              when :msgctxt_plural
                msgid += "\004"
                target = :plural
              else
                target = :normal
              end
            end
          else
            if msgid
              key_existed = targets.assoc(msgid.gsub(/\n/, '\n'))
              if key_existed
                targets[targets.index(key_existed)] = key_existed <<
                file_name + ":" + line_no
              else
                target_obj = TranslationTarget.new([msgid.gsub(/\n/, '\n'), file_name + ":" + line_no])
                target_obj.translator_comment = last_translator_comment \
                  unless last_translator_comment.empty?
                targets << target_obj
              end
              msgid = nil
              target = nil
            end
          end
          targets
        rescue
          $stderr.print "\n\nError: #{$!.inspect} "
          $stderr.print " in #{file_name}:#{tk.line_no}\n\t #{lines[tk.line_no - 1]}" if tk
          $stderr.print "\n"
          exit 1
        end

        case tk 
        when RubyToken::TkCOMMENT_WITH_CONTENT
          last_translator_comment = '' if reset_translator_comment
          last_translator_comment += tk.value
          reset_translator_comment = false
        when RubyToken::TkNL
          last_translator_comment += "\n"
        else
          reset_translator_comment = true
        end
      end
      targets
    end

    def target?(file)  # :nodoc:
      true # always true, as default parser.
    end
  end 
end



if __FILE__ == $0
  require 'pp'
  ARGV.each do |file|
    pp GetText::RubyParser.parse(file)
  end
  
  #rl = RubyLexX.new; rl.set_input(ARGF)  
  #rl.parse do |tk|
    #p tk
  #end  
end
