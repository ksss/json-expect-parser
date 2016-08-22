MRuby::Gem::Specification.new('json-expect-parser') do |spec|
  spec.license = 'MIT'
  spec.author  = 'mruby developers'
  spec.summary = 'A JSON Parser'
  spec.add_dependency('mruby-string-ext', core: 'mruby-string-ext')
  spec.add_dependency('mruby-stringio')
  spec.add_dependency('mruby-onig-regexp')
end
