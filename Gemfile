source ENV['GEM_SOURCE'] || "https://rubygems.org"

gemspec

group :acceptance do
  # TODO: Remove this pin once a new version is shipped
  gem 'beaker',
    git: 'https://github.com/puppetlabs/beaker',
    ref: 'eba5a8868d310461b3380224d84a9b519d0def47'
  gem 'beaker-rspec',                                               '~> 6.1'
  gem 'rspec-prof',                                                 '~> 0.0.7'
end

eval_gemfile "#{__FILE__}.local" if File.exists? "#{__FILE__}.local"

# vim:ft=ruby
