require 'forwardable'
require 'json'

require 'rfacter'

require_relative 'config'
require_relative 'node'
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

    facts = @config.nodes.values.each_with_object({}) do |node, h|
      collection = RFacter::Util::Collection.new(node)
      collection.load_all

      node_facts = if names.empty?
        collection.to_hash
      else
        names.each_with_object({}) do |name, n|
          n[name] = collection.value(name)
        end
      end

      h[node.hostname] = node_facts
    end


    puts JSON.pretty_generate(facts)

    exit 0
  end
end
