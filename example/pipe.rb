#! /usr/bin/env ruby
require 'json/expect/parser'

IO.pipe do |r, w|
  t = Thread.new do
    expect = JSON::Expect::Parser.new(r, buffer_size: 1)
    expect.array do
      puts expect.integer
    end
  end
  w.write "["
  w.write "10,"
  sleep 1
  w.write "20,"
  sleep 1
  w.write "30"
  sleep 1
  w.write "]"
  w.close
  t.join
end
__END__
$ bundle ex ruby example/pipe.rb
10
20
30
