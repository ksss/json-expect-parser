#! /usr/bin/env ruby

require 'benchmark'
require 'get_process_mem'
require 'json/pure/parser'
require 'json/ext/parser'
require 'json/expect/parser'

puts "ruby v#{RUBY_VERSION}"
puts `uname -v`

b = []
30000.times do
  b << %({"abcdefg": 123456, "hijklmn": "fooooooooooooooo", "opqrstu": -123.456})
end
json = "[#{b.join(",")}]"
puts "#{json.length / 1024}KB json string"

puts

[
  ['JSON::Ext::Parser', -> { JSON::Ext::Parser.new(json).parse }],
  ['JSON::Pure::Parser', -> { JSON::Pure::Parser.new(json).parse }],
  ['JSON::Expect::Parser', -> {
    e = JSON::Expect::Parser.new(json)
    e.array do
      e.object do
        e.key
        e.integer
        e.key
        e.string
        e.key
        e.float
      end
    end
  }],
].each do |name, proc|
  GC.start
  Process.wait fork {
    puts "=== #{name} ==="
    mem = GetProcessMem.new.kb
    print "time: "
    puts Benchmark.realtime(&proc)
    puts "memory: #{GetProcessMem.new.kb - mem}KB"
    puts
  }
end
