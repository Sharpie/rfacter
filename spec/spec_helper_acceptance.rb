# See spec/acceptance/nodesets/docker for other options
# that can be passed in via BEAKER_set.
ENV['BEAKER_set'] ||= 'docker/default'

require 'beaker-rspec'
