# frozen_string_literal: true

module JSON
  module Expect
    class Buffer
      def initialize(input, size)
        unless 0 < size
          raise ArgumentError, "negative buffer_size"
        end
        @io = case input
        when String
          StringIO.new(input)
        when IO, StringIO
          input
        else
          raise ArgumentError, "#{input.class} is not supported"
        end
        @string = String.new
        @index = 0
        @size = size
      end

      def fetch(len = 0)
        if str = @io.read(@size + len)
          @string = @string[@index..-1] << str
          @index = 0
        else
          nil
        end
      end

      def next(len = 1)
        if @string.length - @index < len
          if str = @io.read(@size + len)
            @string = @string[@index..-1] << str
            @index = 0
          end
        end

        if @string.length <= @index
          nil
        else
          r = @string[@index, len]
          @index += r.length
          r
        end
      end

      def back(len = 1)
        @index -= len
      end

      def scan(regexp)
        if m = regexp.match(@string, @index)
          @index += m[0].length
          m[0]
        else
          nil
        end
      end

      def next_without_whitespace
        while ch = self.next
          case ch
          when " ", "\t", "\n", "\r"
          else
            return ch
          end
        end
      end

      def rewind
        @string.clear
        @index = 0
        @io.rewind
      end
    end
  end
end
