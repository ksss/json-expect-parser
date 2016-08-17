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
expect.array { p expect.string } #=> JSON::Expect::ParseError: expected "\"" but was "1"
```
