require 'rfacter'
require_relative '../util/logger'

# Class for top-level RFacter configuration
#
# Instances of this class hold top-level configuration values and shared
# service objects such as loggers.
#
# @api public
# @since 0.1.0
class RFacter::Config::Settings
  # Access the logger instance
  #
  # The object stored here should conform to the interface prresented by
  # the Ruby logger.
  #
  # @return [Logger]
  attr_reader :logger

  # A list of nodes to operate on
  #
  # @return [Hash{String => RFacter::Node}] A list of URIs identifying nodes along with the
  #   schemes to use when contacting them.
  attr_reader :nodes

  # A boolean switch for enabling execution profiling
  #
  # @return [Boolean] Defaults to false.
  attr_accessor :profile

  def initialize(**options)
    @logger = RFacter::Util::Logger.new($stderr)
    @logger.level = Logger::WARN

    @profile = false
    @nodes = Hash.new
  end
end
