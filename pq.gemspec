# -*- encoding: utf-8 -*-

require File.expand_path('../lib/pq/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "pq"
  gem.version       = Pq::VERSION
  gem.summary       = %q{postgresql command line interface}
  gem.description   = %q{postgresql command line interface}
  gem.license       = "MIT"
  gem.authors       = ["Hiroshi Toyama"]
  gem.email         = "toyama0919@gmail.com"
  gem.homepage      = "https://github.com/toyama0919/pq"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'thor', '~> 0.19.1'
  gem.add_dependency 'pg'
  gem.add_dependency 'activesupport'
  gem.add_dependency 'activerecord'
  gem.add_dependency 'activerecord-import'

  gem.add_development_dependency 'bundler', '~> 1.7.2'
  gem.add_development_dependency 'pry', '~> 0.10.1'
  gem.add_development_dependency 'rake', '~> 10.3.2'
  gem.add_development_dependency 'rspec', '~> 2.4'
  gem.add_development_dependency 'rubocop', '~> 0.24.1'
  gem.add_development_dependency 'rubygems-tasks', '~> 0.2'
  gem.add_development_dependency 'yard', '~> 0.8'
end
