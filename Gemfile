source ENV['GEM_SOURCE'] || "https://rubygems.org"

gemspec

group :acceptance do
  gem 'beaker-rspec',                                               '~> 6.1'
  # TODO: Remove this pin once the patch gets merged and shipped.
  gem 'beaker',
    git: 'https://github.com/Sharpie/beaker',
    branch: 'docker-disable-reverse-dns'
end

eval_gemfile "#{__FILE__}.local" if File.exists? "#{__FILE__}.local"

# vim:ft=ruby
