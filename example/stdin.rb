#! /usr/bin/env ruby
require 'json/expect/parser'
require 'pp'

pp JSON::Expect::Parser.new(STDIN).parse
__END__
$ echo '["Hello", "World!"]' | bundle ex ruby example/stdin.rb
["Hello", "World!"]
