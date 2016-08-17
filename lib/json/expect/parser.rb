# frozen_string_literal: true

module JSON
  module Expect
    ParseError = Class.new(StandardError)

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

    class Parser
      NUM_FIRST = /\A-|\d/
      # from json/pure
      STRING = /"(?:[^\x0-\x1f"\\] |
         # escaped special characters:
        \\["\\\/bfnrt] |
        \\u[0-9a-fA-F]{4} |
         # match all but escaped special characters:
        \\[\x20-\x21\x23-\x2e\x30-\x5b\x5d-\x61\x63-\x65\x67-\x6d\x6f-\x71\x73\x75-\xff])*
      "/nx
      INTEGER = /\A-?0|-?[1-9]\d*/
      FLOAT = /\A-?
        (?:0|[1-9]\d*)
        (?:
          \.\d+(?i:e[+-]?\d+) |
          \.\d+ |
          (?i:e[+-]?\d+)
        )?
      /x

      def initialize(input, buffer_size: 4092)
        @count_stack = []
        @buffer = Buffer.new(input, buffer_size)
      end

      def object
        return to_enum(:object) unless block_given?

        expect_char("{")
        count_up
        @count_stack.push(0)
        while true
          case ch = @buffer.next_without_whitespace
          when "}"
            check_tail
            break @count_stack.pop
          when "\""
            @buffer.back(ch.length)
            before_count = current_count
            yield
            raise ParseError, "nothing expectation in block" unless before_count != current_count
            check_tail
          else
            raise ParseError, "expected \"}\" or \"\"\" but was #{ch.inspect}"
          end
        end
      end

      def array
        return to_enum(:array) unless block_given?

        expect_char("[")
        count_up
        @count_stack.push(0)
        while true
          case ch = @buffer.next_without_whitespace
          when "]"
            check_tail
            break @count_stack.pop
          when nil
            raise ParseError, "expected any array item but EOF"
          else
            @buffer.back(ch.length)
            before_count = current_count
            yield
            raise ParseError, "nothing expectation in block" unless before_count != current_count
            check_tail
          end
        end
      end

      def key
        buffer = expect_char("\"")
        @buffer.back
        until m = @buffer.scan(STRING)
          if @buffer.fetch.nil?
            raise ParseError, "expected \"\"\" but was EOF"
          end
        end
        expect_char(":")
        m[1..-2]
      end

      def string
        buffer = expect_char("\"")
        @buffer.back
        until m = @buffer.scan(STRING)
          if @buffer.fetch.nil?
            raise ParseError, "expected \"\"\" but was EOF"
          end
        end
        count_up
        check_tail
        m[1..-2]
      end

      def integer
        buffer = @buffer.next_without_whitespace
        if NUM_FIRST =~ buffer
          i = @buffer.next(16)
          buffer << i if i
          while m = INTEGER.match(buffer)
            break if m[0].length != buffer.length
            i = @buffer.next(16)
            break unless i
            buffer << i
          end
          raise ParseError, "expected integer but was #{buffer.inspect}" unless m
          @buffer.back(buffer.length - m[0].length)
          count_up
          check_tail
          m[0].to_i
        else
          raise ParseError, "expected integer but was #{buffer.inspect}"
        end
      end

      def number
        buffer = @buffer.next_without_whitespace
        if NUM_FIRST =~ buffer
          i = @buffer.next(16)
          buffer << i if i
          if buffer[-1] == "."
            i = @buffer.next(16)
            raise ParseError, "expected number after \".\" but nothing" unless i
            buffer << i
          end
          while m = FLOAT.match(buffer)
            break if m[0].length != buffer.length
            i = @buffer.next(16)
            break unless i
            buffer << i
          end
          raise ParseError, "expected number but was #{buffer.inspect}" unless m
          @buffer.back(buffer.length - m[0].length)
          count_up
          check_tail
          m[0].to_f
        else
          raise ParseError, "expected number but was #{buffer.inspect}"
        end
      end
      alias float number

      def boolean
        case ch = @buffer.next_without_whitespace
        when "t"
          if "rue" == (rue = @buffer.next(3))
            count_up
            check_tail
            true
          else
            raise ParseError, "expected true or false but was \"#{ch}#{rue}\""
          end
        when "f"
          if "alse" == (alse = @buffer.next(4))
            count_up
            check_tail
            false
          else
            raise ParseError, "expected true or false but was \"#{ch}#{alse}\""
          end
        else
          raise ParseError, "expected true or false but was \"#{ch}\""
        end
      end

      def null
        case ch = @buffer.next_without_whitespace
        when "n"
          if "ull" == (ull = @buffer.next(3))
            count_up
            check_tail
            nil
          else
            raise ParseError, "expected null but was \"#{ch}#{ull}\""
          end
        else
          raise ParseError, "expected null but was #{ch.inspect}"
        end
      end

      def object_or_null
        null_or { object { yield } }
      end

      def array_or_null
        null_or { array { yield } }
      end

      def null_or
        ch = @buffer.next_without_whitespace
        @buffer.back
        case ch
        when 'n'
          null
        else
          yield
        end
      end

      def value
        ch = @buffer.next_without_whitespace
        @buffer.back
        case ch
        when "["
          array.map { value }
        when "{"
          Hash[object.map { [key, value] }]
        when "n"
          null
        when "t", "f"
          boolean
        when "\""
          string
        when NUM_FIRST
          number
        else
          raise ParseError, "expected any value but was #{ch.inspect}"
        end
      end
      alias parse value

      def rewind
        @buffer.rewind
      end

      private

      def count_up
        if !@count_stack.empty?
          @count_stack[-1] += 1
        end
      end

      def current_count
        @count_stack[-1]
      end

      def check_tail
        case ch = @buffer.next_without_whitespace
        when ","
          raise ParseError, "unexpected \",\"" if @count_stack.empty?
          ch = @buffer.next_without_whitespace
          raise ParseError, "expected next token but was EOF" unless ch
          case ch
          when "]", "}", ","
            raise ParseError, "expected next token but was #{ch.inspect}"
          else
            @buffer.back
          end
        when nil
        else
          @buffer.back
        end
      end

      def expect_char(expect)
        actual = @buffer.next_without_whitespace
        unless actual == expect
          raise ParseError, "expected #{expect.inspect} but was #{actual.inspect}"
        end
        actual
      end
    end
  end
end
