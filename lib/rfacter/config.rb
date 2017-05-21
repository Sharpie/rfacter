require 'optparse'
require 'optparse/uri'
require 'logger'

require 'rfacter'

require_relative 'config/settings'
require_relative 'node'

# Stores and sets global configuration
#
# This module stores a global instance of {RFacter::Config::Settings}
# and contains methods for initializing the settings instance from
# various sources.
#
# @api public
# @since 0.1.0
module RFacter::Config
  # Return global configuration
  #
  # @return [RFacter::Config::Settings]
  def self.config
    @settings ||= RFacter::Config::Settings.new
  end

  # Set global configuration from an argument vector
  #
  # This method calls {.parse_argv} and uses the results to update the
  # settings instance returned by {.config}.
  #
  # @param argv [Array<String>] A list of strings passed as command line
  #   arguments.
  #
  # @return [Array<string>] An array of command line arguments that were
  #   not consumed by the parser.
  def self.configure_from_argv!(argv)
    args, _ = parse_argv(argv, self.config)

    args
  end

  # Configure a settings instance by parsing an argument vector
  #
  # @param argv [Array<String>] Command line arguments as an array of
  #   strings.
  #
  # @param settings [RFacter::Config::Settings, nil] A settings object to
  #   configure. A new object will be created if nothing is passed.
  #
  # @return [Array<Array<String>, RFacter::Config::Settings>>] A tuple
  #   containing a configured instance of {RFacter::Config::Settings}
  #   followed by an array of command line arguments that were not consumed
  #   by the parser.
  def self.parse_argv(argv, settings = nil)
    settings ||= RFacter::Config::Settings.new
    parser = OptionParser.new
    args = argv.dup

    parser.separator("\nOptions\n=======")

    parser.on('--version', 'Print version number and exit.') do
      puts RFacter::VERSION
      exit 0
    end

    parser.on('-h', '--help', 'Print this help message.') do
      puts parser.help
      exit 0
    end

    parser.on('-v', '--verbose', 'Raise log level to INFO.') do
      settings.logger.level = Logger::INFO
    end

    parser.on('-d', '--debug', 'Raise log level to DEBUG.') do
      settings.logger.level = Logger::DEBUG
    end

    parser.on('-t', '--trace', 'Trace fact resolution times.') do
      settings.trace = true
    end

    parser.on('-n', '--node', '=MANDATORY', URI, 'Add a node by URI.') do |uri|
      node = RFacter::Node.new(uri)
      settings.nodes[node.hostname] = node
    end

    parser.parse!(args)

    [args, settings]
  end
end
