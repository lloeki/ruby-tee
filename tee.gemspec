# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'tee/version'

Gem::Specification.new do |s|
  s.name        = 'tee'
  s.version     = Tee::VERSION
  s.authors     = ['Loic Nageleisen']
  s.email       = ['loic.nageleisen@gmail.com']
  s.homepage    = 'http://github.com/lloeki/ruby-tee'
  s.summary     = %q{Teeing enumerables}
  s.description = %q{Allows enumerables to be teed via fibers}
  s.license     = 'MIT'
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n")
                                           .map { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_development_dependency 'rspec', '~> 2.14'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'pry'
end
