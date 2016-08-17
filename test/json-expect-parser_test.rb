require 'json/expect/parser'

module JSONExpectParserTest
  def test_initialize(t)
    f = File.open(__FILE__)
    [
      %([]),
      StringIO.new(%([])),
      f,
    ].each do |io|
      e = JSON::Expect::Parser.new(io)
      unless JSON::Expect::Parser === e
        t.error("expect JSON::Expect::Parser but was #{e.class}")
      end
    end

    [
      nil,
      1,
      1.1,
      1.rationalize,
      [],
      {},
      :sym,
    ].each do |io|
      begin
        JSON::Expect::Parser.new(io)
      rescue ArgumentError
      else
        t.error("expect raise ArgumentError but nothing")
      end
    end

    begin
      JSON::Expect::Parser.new('{}', buffer_size: -1)
    rescue ArgumentError
    else
      t.error("expect raise ArgumentError but nothing")
    end
  ensure
    f.close
  end

  def test_base(t)
    [
      ["null", ->(e) { e.null }, nil],
      ["true", ->(e) { e.boolean }, true],
      ["false", ->(e) { e.boolean }, false],
      ["0", ->(e) { e.integer }, 0],
      ["0", ->(e) { e.number }, 0.0],
      ["-123", ->(e) { e.integer }, -123],
      ["123", ->(e) { e.number }, 123.0],
      ["100000000000000.1", ->(e) { e.number }, 100000000000000.1],
      ["-10000000000000000.456", ->(e) { e.number }, -10000000000000000.456],
      ['""', ->(e) { e.string }, ""],
      ['"hello"', ->(e) { e.string }, "hello"],
      ['[]', ->(e) { e.array {} }, 0],
      ['[0, 1, 2]', ->(e) { e.array { e.integer } }, 3],
      ["[-1.1, 2.2, -3.3]", ->(e) { e.array { e.float } }, 3],
      ['[true, false, true, false]', ->(e) { e.array { e.boolean } }, 4],
      ['[null, null, null]', ->(e) { e.array { e.null } }, 3],
      ['[false, null, true]', ->(e) { e.array { e.boolean; e.null; e.boolean } }, 3],
      ['[[], [], []]', ->(e) { e.array { e.array {} } }, 3],
      ['[{}, {}, {}]', ->(e) { e.array { e.object {} } }, 3],
      ['[[[]]]', ->(e) { e.array { e.array { e.array {} } } }, 1],
      ['[1, null, -1.23, false, "hi", [], {}, null]', ->(e) { e.array { e.integer; e.null; e.float; e.boolean; e.string; e.array {}; e.object {}; e.null } }, 8],
      ['{}', ->(e) { e.object {} }, 0],
      ['{"a": {"b": {"c": {}}}}', ->(e) { e.object { e.key; e.object { e.key; e.object { e.key; e.object {} } } } }, 1],
      ['{"a": [1], "b": [2], "c": [3]}', ->(e) { e.object { e.key; e.array { e.integer } } }, 3],
      ['{"a":1}{"b":2}{"c":3}', ->(e) { e.object { e.key; e.integer }; e.object { e.key; e.integer }; e.object { e.key; e.integer } }, 1],
    ].each do |json, block, expect|
      e = JSON::Expect::Parser.new(json)
      actual = block.call(e)
      unless actual == expect
        t.error("#{json.inspect} expected #{expect.inspect} but was #{actual.inspect}")
      end
    end
  end

  def test_parse_error(t)
    [
      [",1", ->(e) { e.integer }, /expected integer but was ","/],
      ["1,", ->(e) { e.integer }, /unexpected ","/],
      ["1.", ->(e) { e.number }, /expected number after "." but nothing/],
      ["-", ->(e) { e.integer }, /expected integer but was "-"/],
      ["-", ->(e) { e.number }, /expected number but was "-"/],
      ["1", ->(e) { e.integer; e.integer }, /expected integer but was nil/],
      ["1", ->(e) { e.string }, /expected "\\"" but was "1"/],
      ["1", ->(e) { e.array {} }, /expected "\[" but was "1"/],
      ["1", ->(e) { e.object {} }, /expected "{" but was "1"/],
      ["1", ->(e) { e.boolean }, /expected true or false but was "1"/],
      ["1", ->(e) { e.null }, /expected null but was "1"/],
      ["\"foo", ->(e) { e.string }, /expected """ but was EOF/],
      ["truii", ->(e) { e.boolean }, /expected true or false but was "trui"/],
      ["falsss", ->(e) { e.boolean }, /expected true or false but was "falss"/],
      ["truue", ->(e) { e.boolean }, /expected true or false but was "truu"/],
      ["nul11", ->(e) { e.null }, /expected null but was "nul1"/],
      [",", ->(e) { e.object {} }, /expected "{" but was ","/],
      [",", ->(e) { e.array {} }, /expected "\[" but was ","/],
      ["[,]", ->(e) { e.array {} }, /nothing expectation in block/],
      ["[", ->(e) { e.array {} }, /expected any array item but EOF/],
      ["]", ->(e) { e.array {} }, /expected "\[" but was "\]"/],
      ["[1", ->(e) { e.array { e.integer } }, /expected any array item but EOF/],
      ["[1]", ->(e) { e.array {} }, /nothing expectation in block/],
      ["[,1]", ->(e) { e.array { e.integer } }, /expected integer but was ","/],
      ["[ , 1 , ]", ->(e) { e.array { e.integer } }, /expected integer but was ","/],
      ["[ 1 , ]", ->(e) { e.array { e.integer } }, /expected next token but was "\]"/],
      ["[ 1 , 2 , ]", ->(e) { e.array { e.integer } }, /expected next token but was "\]"/],
      ["[}", ->(e) { e.array {} }, /nothing expectation in block/],
      [%( { "a" : 1 } ), ->(e) { e.object {} }, /nothing expectation in block/],
      [%( { 1 : "a" , } ), ->(e) { e.object { e.integer; e.string } }, /expected "}" or """ but was "1"/],
      [%( { "a" : 1 } ), ->(e) { e.object {} }, /nothing expectation in block/],
      [%( { , "a" : 1 } ), ->(e) { e.object { e.key; e.integer } }, /expected "}" or """ but was ","/],
    ].each do |json, block, expect|
      e = JSON::Expect::Parser.new(json)
      begin
        block.call(e)
      rescue JSON::Expect::ParseError => e
        unless expect =~ e.message
          t.log(json)
          t.error("expected #{expect} but was #{e.message}")
        end
      rescue => e
        t.log(e.message)
        t.log(e.backtrace.join("\n"))
        t.error("#{json.inspect} expected raise JSON::Expect::ParseError but #{e.class}")
      else
        t.error("#{json.inspect} expected raise JSON::Expect::ParseError but nothing")
      end
    end
  end

  def test_rewind(t)
    e = JSON::Expect::Parser.new(%([10, 20, 30]))
    e.array { break }
    e.integer
    actual = e.rewind
    unless 0 == actual
      t.error("expected 0 but was #{actual}")
    end

    actual = e.array { break e.integer }
    unless 10 == actual
      t.error("expected 20 but was #{actual}")
    end
  end

  def test_array(t)
    e = JSON::Expect::Parser.new(%([10, 20, 30]))
    expect = [10, 20, 30]
    actual = []
    e.array { actual << e.integer }
    unless actual == expect
      t.error("expected #{expect} but was #{actual}")
    end
  end

  def test_array_with_different_types(t)
    e = JSON::Expect::Parser.new(%([10, "foo", true, null, [1, [2]], {"a": -10.1}]))
    expect = [10, "foo", true, nil, 1, 2, 1, 2, "a", -10.1, 1]
    actual = []
    e.array do
      actual << e.integer
      actual << e.string
      actual << e.boolean
      actual << e.null
      actual << e.array do
        actual << e.integer
        actual << e.array do
          actual << e.integer
        end
      end
      actual << e.object do
        actual << e.key
        actual << e.float
      end
    end
    unless expect == actual
      t.error("expected #{expect} but was #{actual}")
    end
  end

  def test_array_with_break(t)
    e = JSON::Expect::Parser.new(%([10, 20, 30]))
    expect = [10, 20, 30]
    actual = []

    e.array do
      actual << e.integer
      break
    end
    actual << e.integer
    actual << e.integer
    unless actual == expect
      t.error("expected #{expect} but was #{actual}")
    end
  end

  def test_array_with_enumerable(t)
    e = JSON::Expect::Parser.new(%([10, 20, 30]))
    unless Enumerable === e.array
      t.error("expected Enumerable but was #{e.array.class}")
    end

    expect = [10, 20, 30]
    actual = e.array.map do
      e.integer
    end
    unless actual == expect
      t.error("expected #{expect} but was #{actual}")
    end
  end

  def test_array_or_null(t)
    e = JSON::Expect::Parser.new(%([[10], null, [20, 30], null]))
    expect = [1, nil, 2, nil]
    actual = e.array.map { e.array_or_null { e.integer } }
    unless actual == expect
      t.error("expected #{expect} but was #{actual}")
    end
  end

  def test_object(t)
    e = JSON::Expect::Parser.new(%({"foo": "bar", "baz": "qux"}))
    expect = { "foo" => "bar", "baz" => "qux" }
    actual = {}
    e.object do
      actual[e.key] = e.string
    end
    unless actual == expect
      t.error("expected #{expect} but was #{actual}")
    end
  end

  def test_object_with_enumerable(t)
    e = JSON::Expect::Parser.new(%({"foo": "bar", "baz": "qux"}))
    expect = { "foo" => "bar", "baz" => "qux" }
    actual = Hash[e.object.map { [e.key, e.string] }]
    unless actual == expect
      t.error("expected #{expect} but was #{actual}")
    end
  end

  def test_object_or_null(t)
    e = JSON::Expect::Parser.new(%([{"foo": "bar"}, null, {"baz": "qux"}, null]))
    expect = ["foo", "bar", 1, nil, "baz", "qux", 1, nil, 4]
    actual = []
    actual << e.array do
      actual << e.object_or_null do
        actual << e.key
        actual << e.string
      end
    end
    unless actual == expect
      t.error("expected #{expect} but was #{actual}")
    end
  end

  def test_value(t)
    e = JSON::Expect::Parser.new(%([1, "foo", null, true, false, [1], {"a": 1}]))
    expect = [1, "foo", nil, true, false, [1], { "a" => 1 }]
    unless expect == e.value
      e.rewind
      t.error("expected #{expect} but was #{e.value}")
    end

    e = JSON::Expect::Parser.new(%({"foo": [10, true, {"bar": [{"baz": 20}]}]}))
    expect = { "foo" => [10.0, true, { "bar" => [{ "baz" => 20.0 }] }] }
    unless expect == e.value
      e.rewind
      t.error("expected #{expect} but was #{e.value}")
    end
  end

  def test_value_parse_error(t)
    e = JSON::Expect::Parser.new(%({a:1}))
    begin
      e.value
    rescue JSON::Expect::ParseError
    else
      t.error("expected JSON::Expect::ParseError but was nothing")
    end
  end
end
