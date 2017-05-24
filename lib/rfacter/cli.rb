require 'forwardable'
require 'json'

require 'rfacter'

require_relative 'config'
require_relative 'node'
require_relative 'factset'
require_relative 'util/collection'

# RFacter Command Line Interface module
#
# @api public
# @since 0.1.0
module RFacter::CLI
  extend SingleForwardable

  delegate([:logger] => :@config)

  def self.run(argv)
    names = RFacter::Config.configure_from_argv!(argv)
    @config = RFacter::Config.config

    if @config.nodes.empty?
      @config.nodes['localhost'] = RFacter::Node.new('localhost')
    end

    logger.info('cli::run') { "Configured nodes: #{@config.nodes.values.map(&:hostname)}" }

    factset = RFacter::Factset.new(@config.nodes.values)

    node_facts = if names.empty?
                   factset.to_hash
                 else
                   factset.value(names)
                 end

    puts JSON.pretty_generate(node_facts)

    exit 0
  end
end
