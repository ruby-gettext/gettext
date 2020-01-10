module Fixtures
  module Method_
    class PercentStrings
      include GetText

      bindtextdomain("_", :path => Helper::Path.locale_path)

      def symbol_array
        _(%i(hello world))
      end

      def symbol
        _(%s(hello world))
      end

      def string
        _(%(hello world))
      end

      def string_array
        _(%w(hello world))
      end

      def execute
        _(%x(echo hello world))
      end
    end
  end
end
