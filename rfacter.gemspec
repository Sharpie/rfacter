# -*- encoding: utf-8 -*-
require File.join([File.dirname(__FILE__),'lib','rfacter','version.rb'])

Gem::Specification.new do |s|
  s.name = 'rfacter'
  s.version = RFacter::VERSION
  s.summary = 'Reduced, Remote-enabled, Ruby fork of Facter 2.x'
  s.description = <<-EOS
RFacter is a library for collecting facts from remote system(s) by executing
commands over transports such as SSH and WinRM.
EOS

  s.required_ruby_version = '>= 2.1.0'

  s.license = 'Apache-2.0'
  s.authors = ['Charlie Sharpsteen', 'Puppet Labs']
  s.email = 'source@sharpsteen.net'
  s.homepage = 'https://github.com/Sharpie/rfacter'
  s.platform = Gem::Platform::RUBY
  s.files = Dir['bin/*'] + Dir['lib/**/*.rb']
  s.require_paths = ['lib']
  s.bindir = 'bin'
  s.executables = ['rfacter']

  s.add_dependency 'train',                                     '~> 0.23.0'
  s.add_dependency 'concurrent-ruby',                           '~> 1.0'

  s.add_development_dependency 'inch',                          '~> 0.7'
  s.add_development_dependency 'rspec',                         '~> 3.1'
end

# vim:ft=ruby
