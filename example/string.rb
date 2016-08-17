#! /usr/bin/env ruby
require 'json/expect/parser'

values = []
expect = JSON::Expect::Parser.new(%([10, 20, 30]))
expect.array do
  values << expect.integer
end
p values
#=> [10, 20, 30]
