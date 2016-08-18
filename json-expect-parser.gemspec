# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'json/expect/parser/version'

Gem::Specification.new do |spec|
  spec.name          = "json-expect-parser"
  spec.version       = JSON::Expect::Parser::VERSION
  spec.authors       = ["ksss"]
  spec.email         = ["co000ri@gmail.com"]

  spec.summary       = "JSON expect parser"
  spec.description   = "An alternative JSON parser"
  spec.homepage      = "https://github.com/ksss/json-expect-parser"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{_test.rb}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "json"
  spec.add_development_dependency "get_process_mem"
  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rgot"
end
