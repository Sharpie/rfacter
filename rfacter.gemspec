# -*- encoding: utf-8 -*-
require File.join([File.dirname(__FILE__),'lib','rfacter','version.rb'])

Gem::Specification.new do |s|
  s.name = 'rfacter'
  s.version = RFacter::VERSION
  s.summary = 'Reduced, Remote-enabled, Ruby fork of Facter 2.x'

  s.license = 'Apache-2.0'
  s.authors = ['Charlie Sharpsteen', 'Puppet Labs']
  s.email = 'source@sharpsteen.net'
  s.platform = Gem::Platform::RUBY
  s.files = Dir['bin/*'] + Dir['lib/**/*.rb']
  s.require_paths = ['lib']
  s.bindir = 'bin'
  s.executables = ['rfacter']
end

# vim:ft=ruby
