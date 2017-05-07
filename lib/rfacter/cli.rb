require 'forwardable'
require 'json'

require 'rfacter'

require_relative 'config'
require_relative 'node'
require_relative 'util/collection'

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

    collection = RFacter::Util::Collection.new
    collection.load_all

    facts = @config.nodes.values.inject(Hash.new) do |h, node|
      h[node.hostname] = collection.to_hash(node)

      # TODO: Implement per-node fact values.
      collection.flush

      h
    end


    puts JSON.pretty_generate(facts)

    exit 0
  end
end
