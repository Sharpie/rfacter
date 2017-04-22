require 'forwardable'

require 'rfacter'

require_relative 'config'
require_relative 'node'

module RFacter::CLI
  extend SingleForwardable

  delegate([:logger] => :@config)

  def self.run(argv)
    args = RFacter::Config.configure_from_argv!(argv)
    @config = RFacter::Config.config

    if @config.nodes.empty?
      @config.nodes['localhost'] = RFacter::Node.new('localhost')
    end

    logger.info('cli::run') { "Configured nodes: #{@config.nodes.values.map(&:hostname)}" }

    exit 0
  end
end
