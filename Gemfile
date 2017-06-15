source ENV['GEM_SOURCE'] || "https://rubygems.org"

gemspec

group :acceptance do
  gem 'beaker',                                                     '~> 3.18'
  gem 'beaker-rspec',                                               '~> 6.1'
end

eval_gemfile "#{__FILE__}.local" if File.exists? "#{__FILE__}.local"

# vim:ft=ruby
