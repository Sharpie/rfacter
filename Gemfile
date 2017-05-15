source ENV['GEM_SOURCE'] || "https://rubygems.org"

gemspec

group :acceptance do
  # TODO: Remove this pin once the patch gets merged and shipped.
  gem 'beaker',
    git: 'https://github.com/Sharpie/beaker',
    branch: 'docker-disable-reverse-dns'
  gem 'beaker-rspec',                                               '~> 6.1'
  gem 'rspec-prof',                                                 '~> 0.0.7'
end

eval_gemfile "#{__FILE__}.local" if File.exists? "#{__FILE__}.local"

# vim:ft=ruby
