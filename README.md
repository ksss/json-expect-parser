json-expect-parser
===

An alternative JSON parser.

## Synopsis

t.json

```json
[
  {
    "id": 1,
    "name": "ksss",
    "admin": true
  },
  {
    "id": 2,
    "name": "foo",
    "admin": false
  },
  {
    "id": 3,
    "name": "bar",
    "admin": false
  }
]
```

```rb
require 'json/expect/parser'

File.open("t.json") do |io|
  expect = JSON::Expect::Parser.new(io)
  expect.array do
    expect.object do
      case expect.key
      when "id"
        p expect.integer #=> 1, 2, 3
      when "name"
        p expect.string #=> "ksss", "foo", "bar"
      when "admin"
        p expect.boolean #=> true, false, false
      end
    end
  end
end
```

## Explicitly parse

json-expect-parser parse JSON explicitly.

```rb
expect = JSON::Expect::Parser.new(%([10, 20, 30]))
expect.array { p expect.integer } #=> 10, 20, 30
```

If get unexpected value, It failed.

```rb
expect = JSON::Expect::Parser.new(%([10, 20, 30]))
expect.array { p expect.string }
#=> JSON::Expect::ParseError: expected "\"" but was "1"
```

## API

### object

```rb
expect = JSON::Expect::Parser.new(%({"a": 10, "b": 20}))

expect.object
#=> #<Enumerator: #<JSON::Expect::Parser ...>>

expect.object do
  expect.key #=> "a", "b"
  expect.integer #=> 10, 20
end
```

### array

```rb
expect = JSON::Expect::Parser.new(%(["foo", "bar", "baz"]))

expect.array
#=> #<Enumerator: #<JSON::Expect::Parser ...>>

expect.array do  
  expect.string #=> "foo", "bar", "baz"
end

expect.rewind

expect.array.map { expect.string }
#=> ["foo", "bar", "baz"]
```

### integer

```rb
expect = JSON::Expect::Parser.new(%(100))
expect.integer #=> 100
```

### number(alias float)

```rb
expect = JSON::Expect::Parser.new(%(1.1))
expect.float #=> 1.1
```

### string

```rb
expect = JSON::Expect::Parser.new(%("foo"))
expect.string #=> "foo"
```

### key

Use in `object` then get object key string

### boolean

```rb
expect = JSON::Expect::Parser.new(%("true"))
expect.boolean #=> true
```

### null

```rb
expect = JSON::Expect::Parser.new(%("null"))
expect.null #=> nil
```

### object_or_null

```rb
expect = JSON::Expect::Parser.new(%([{"a": 1}, null]))
expect.array do
  expect.object_or_null do
    expect.key #=> "a"
    expect.integer #=> 1
  end
end
```

### array_or_null

```rb
expect = JSON::Expect::Parser.new(%([[1, 2, 3], null]))
expect.array do
  expect.array_or_null do
    expect.integer #=> 1, 2, 3
  end
end
```

### null_or

```rb
expect = JSON::Expect::Parser.new(%({"a": "foo", "b": null}))
expect.object do
  expect.key #=> "a", "b"
  expect.null_or { expect.string } #=> "foo", nil
end
```

### value(alias parse)

```rb
expect = JSON::Expect::Parser.new(%([[true, false], null, 1, "foo"]))
expect.value
#=> [[true, false], nil, 1.0, "foo"]
```

### rewind

```rb
expect = JSON::Expect::Parser.new(%("foo"))
expect.string #=> "foo"
expect.string #=> "foo"
#=> JSON::Expect::ParseError: expected "\"" but was nil
expect.rewind
expect.string #=> "foo"
```

# Benchmark

```
$ bundle ex benchmark/comparison.rb
ruby v2.3.1
Darwin Kernel Version 15.6.0: Thu Jun 23 18:25:34 PDT 2016; root:xnu-3248.60.10~1/RELEASE_X86_64
2109KB json string

=== JSON::Ext::Parser ===
time: 0.08309706707950681
memory: 30164.0KB

=== JSON::Pure::Parser ===
time: 0.4895962669979781
memory: 35684.0KB

=== JSON::Expect::Parser ===
time: 0.7294884130824357
memory: 23568.0KB
```
