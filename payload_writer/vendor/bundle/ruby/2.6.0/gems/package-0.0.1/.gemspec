# encoding: utf-8

GemSpec = Gem::Specification.new do |gem|
  gem.name = 'package'
  gem.version = '0.0.1'
  gem.license = 'MIT'
  gem.required_ruby_version = '>= 1.9.1'

  gem.authors << 'Ingy döt Net'
  gem.email = 'ingy@ingy.net'
  gem.summary = 'The Package package package package!'
  gem.description = <<-'.'
Package is a general purpose tool for creating new packages.
.
  gem.homepage = 'http://acmeism.org'

  gem.files = `git ls-files`.lines.map{|l|l.chomp}
#   gem.add_development_dependency 'testml-lite', '>= 0.0.1'
end
