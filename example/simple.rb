#! /usr/bin/env ruby
require 'json/expect/parser'

values = []
expect = JSON::Expect::Parser.new(DATA)
expect.array do
  expect.object do
    case expect.key
    when "id"
      values << expect.integer
    when "name"
      values << expect.string
    when "admin"
      values << expect.boolean
    end
  end
end
p values
# $ bundle ex ruby example/simple.rb
# [1, "ksss", true, 2, "foo", false, 3, "bar", false]
__END__
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
