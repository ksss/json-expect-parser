require 'json/expect/parser'
require 'json/pure'
require 'json/ext'

module JSONExpectParserBenchmarkTest
  def setup_integer
    [*1..1000].to_json
  end

  def benchmark_integer_ext(b)
    json = setup_integer
    b.reset_timer

    i = 0
    while i < b.n
      JSON::Ext::Parser.new(json).parse
      i += 1
    end
  end

  def benchmark_integer_pure(b)
    json = setup_integer
    b.reset_timer

    i = 0
    while i < b.n
      JSON::Pure::Parser.new(json).parse
      i += 1
    end
  end

  def benchmark_integer_expect(b)
    json = setup_integer
    b.reset_timer

    i = 0
    while i < b.n
      e = JSON::Expect::Parser.new(json)
      e.array do
        e.integer
      end
      i += 1
    end
  end

  def setup_string
    ([*'a'..'z'] + [*'A'..'Z']).map { |i| i * 16 }.to_json
  end

  def benchmark_string_ext(b)
    json = setup_string
    b.reset_timer

    i = 0
    while i < b.n
      JSON::Ext::Parser.new(json).parse
      i += 1
    end
  end

  def benchmark_string_pure(b)
    json = setup_string
    b.reset_timer

    i = 0
    while i < b.n
      JSON::Pure::Parser.new(json).parse
      i += 1
    end
  end

  def benchmark_string_expect(b)
    json = setup_string
    b.reset_timer

    i = 0
    while i < b.n
      e = JSON::Expect::Parser.new(json)
      e.array do
        e.string
      end
      i += 1
    end
  end
end
