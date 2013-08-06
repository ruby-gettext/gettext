# -*- coding: utf-8 -*-
=begin
  parser/ruby.rb - parser for ruby script

  Copyright (C) 2013       Kouhei Sutou <kou@clear-code.com>
  Copyright (C) 2003-2009  Masao Mutoh
  Copyright (C) 2005       speakillof
  Copyright (C) 2001,2002  Yasushi Shoji, Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.

=end

require 'irb/ruby-lex'
require 'stringio'
require 'gettext/tools/po_entry'

module GetText
  class RubyLexX < RubyLex  # :nodoc: all
    # Parser#parse resemlbes RubyLex#lex
    def parse
      until (  (tk = token).kind_of?(RubyToken::TkEND_OF_SCRIPT) && !@continue or tk.nil?  )
        s = get_readed
        if RubyToken::TkSTRING === tk or RubyToken::TkDSTRING === tk
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
          if tk.is_a? TkSTRING or tk.is_a? TkDSTRING
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

    # Original parser does not keep the content of the comments,
    # so monkey patching this with new token type and extended
    # identify_comment implementation
    RubyToken.def_token :TkCOMMENT_WITH_CONTENT, TkVal

    def identify_comment
      @ltype = "#"
      get_readed # skip the hash sign itself

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

  # Extends POEntry for RubyParser.
  # Implements a sort of state machine to assist the parser.
  module POEntryForRubyParser
    # Supports parsing by setting attributes by and by.
    def set_current_attribute(str)
      param = @param_type[@param_number]
      raise ParseError, 'no more string parameters expected' unless param
      set_value(param, str)
    end

    def init_param
      @param_number = 0
      self
    end

    def advance_to_next_attribute
      @param_number += 1
    end
  end
  class POEntry
    include POEntryForRubyParser
    alias :initialize_old :initialize
    def initialize(type)
      initialize_old(type)
      init_param
    end
  end

  class RubyParser
    ID = ['gettext', '_', 'N_', 'sgettext', 's_']
    PLURAL_ID = ['ngettext', 'n_', 'Nn_', 'ns_', 'nsgettext']
    MSGCTXT_ID = ['pgettext', 'p_']
    MSGCTXT_PLURAL_ID = ['npgettext', 'np_']

    class << self
      def target?(file)  # :nodoc:
        true # always true, as the default parser.
      end

      def parse(path)
        parser = new(path)
        parser.parse
      end
    end

    def initialize(path)
      @path = path
    end

    # (Since 2.1.0) the 2nd parameter is deprecated
    # (and ignored here).
    # And You don't need to keep the poentries as unique.

    def parse  # :nodoc:
      source = IO.read(@path)

      encoding = detect_encoding(source) || source.encoding
      source.force_encoding(encoding)

      parse_lines(source.each_line.to_a)
    end

    def detect_encoding(source)
      binary_source = source.dup.force_encoding("ASCII-8BIT")
      if /\A.*coding\s*[=:]\s*([[:alnum:]\-_]+)/ =~ binary_source
        $1.gsub(/-(?:unix|mac|dos)\z/, "")
      else
        nil
      end
    end

    def parse_lines(lines)  # :nodoc:
      po = []
      file = StringIO.new(lines.join + "\n")
      rl = RubyLexX.new
      rl.set_input(file)
      rl.skip_space = true
      #rl.readed_auto_clean_up = true

      po_entry = nil
      line_no = nil
      last_comment = ''
      reset_comment = false
      ignore_next_comma = false
      rl.parse do |tk|
        begin
          ignore_current_comma = ignore_next_comma
          ignore_next_comma = false
          case tk
          when RubyToken::TkIDENTIFIER, RubyToken::TkCONSTANT
            if store_po_entry(po, po_entry, line_no, last_comment)
              last_comment = ""
            end
            if ID.include?(tk.name)
              po_entry = POEntry.new(:normal)
            elsif PLURAL_ID.include?(tk.name)
              po_entry = POEntry.new(:plural)
            elsif MSGCTXT_ID.include?(tk.name)
              po_entry = POEntry.new(:msgctxt)
            elsif MSGCTXT_PLURAL_ID.include?(tk.name)
              po_entry = POEntry.new(:msgctxt_plural)
            else
              po_entry = nil
            end
            line_no = tk.line_no.to_s
          when RubyToken::TkSTRING, RubyToken::TkDSTRING
            po_entry.set_current_attribute tk.value if po_entry
          when RubyToken::TkPLUS, RubyToken::TkNL
            #do nothing
          when RubyToken::TkINTEGER
            ignore_next_comma = true
          when RubyToken::TkCOMMA
            unless ignore_current_comma
              po_entry.advance_to_next_attribute if po_entry
            end
          else
            if store_po_entry(po, po_entry, line_no, last_comment)
              po_entry = nil
              last_comment = ""
            end
          end
        rescue
          $stderr.print "\n\nError"
          $stderr.print " parsing #{@path}:#{tk.line_no}\n\t #{lines[tk.line_no - 1]}" if tk
          $stderr.print "\n #{$!.inspect} in\n"
          $stderr.print $!.backtrace.join("\n")
          $stderr.print "\n"
          exit 1
        end

        case tk
        when RubyToken::TkCOMMENT_WITH_CONTENT
          last_comment = "" if reset_comment
          if last_comment.empty?
            # new comment from programmer to translator?
            comment1 = tk.value.lstrip
            if comment1 =~ /^TRANSLATORS\:/
              last_comment = $'
            end
          else
            last_comment += "\n"
            last_comment += tk.value
          end
          reset_comment = false
        when RubyToken::TkNL
        else
          reset_comment = true
        end
      end
      po
    end

    private
    def store_po_entry(po, po_entry, line_no, last_comment) #:nodoc:
      if po_entry && po_entry.msgid
        po_entry.references << @path + ":" + line_no
        po_entry.add_comment(last_comment) unless last_comment.empty?
        po << po_entry
        true
      else
        false
      end
    end
  end
end
