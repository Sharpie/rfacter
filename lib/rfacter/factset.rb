require 'forwardable'

require 'rfacter'

require_relative 'config'
require_relative 'node'
require_relative 'util/collection'

# A class that can retrieve facts from several nodes
#
# A factset joins instances of {RFacter::Node} to {RFacter::Util::Collection}
# and enables parallel and asynchronous resolution of fact values across
# several nodes. Supports retrieving single facts asynchronously via {#fetch}
# and in a blocking fashion via {#value}. All facts can be retrieved
# asynchronously via {#fetch_all} and in a blocking fashion via {#to_hash}.
#
# @api public
# @since 0.1.0
class RFacter::Factset
  extend Forwardable

  instance_delegate([:logger] => :@config)

  # Returns a new instance of Factset
  #
  # @param nodes [Array<RFacter::Node>] An array of node objects to collect
  #   facts from.
  def initialize(nodes, config: RFacter::Config.config, **opts)
    @config = config

    @collections = nodes.each_with_object({}) do |node, hash|
      hash[node.hostname] = RFacter::Util::Collection.new(node)
    end
  end

  # Asynchronously fetch the value of a fact from each node
  #
  # This method spawns a background thread per node which resolves the value
  # of a fact specified by `query`.
  #
  # @param queries [Array<String>] The names of the facts to fetch.
  #
  # @return [Concurrent::Future{String => Hash}]
  #   A future that will return a hash mapping the node id to a hash containing
  #   the resolved facts when `value` is called.
  def fetch(queries)
    queries = Array(queries)
    # Spawn async lookups in the background for each node.
    futures = @collections.each_with_object({}) do |(name, collection), hash|
      hash[name] = {}
      queries.each do |query|
        hash[name][query] = collection.async.value(query)
      end
    end

    # Return a future with the resolved values.
    Concurrent::Future.execute do
      futures.each_with_object({}) do |(name, ivars), hash|
        hash[name] = ivars.each_with_object({}) do |(query, ivar), results|
          # TODO: Add exception handling for failed futures.
          results[query] = ivar.value
        end
      end
    end
  end

  # Fetch the value of a fact from each node
  #
  # This method calls {#fetch} and then blocks until the result is available.
  #
  # @return [Hash{String => Hash}]
  #   A hash mapping the node id to a hash containing the resolved facts.
  def value(queries)
    fetch(queries).value
  end

  # Asynchronously fetch all facts from each node
  #
  # This method spawns a background thread per node which resolves all
  # fact values for each node.
  #
  # @return [Concurrent::Future{String => Hash}]
  #   A future that will return a hash mapping the node id to a hash containing
  #   the resolved facts when `value` is called.
  def fetch_all
    futures = @collections.each_with_object({}) do |(name, collection), hash|
      collection.async.load_all
      hash[name] = collection.async.to_hash
    end

    Concurrent::Future.execute do
      futures.each_with_object({}) do |(name, future), hash|
        # TODO: Add exception handling for failed futures.
        hash[name] = future.value
      end
    end
  end

  # Fetch all facts from each node
  #
  # This method calls {#fetch_all} and then blocks until the result
  # is available.
  #
  # @return [Hash{String => Hash}]
  #   A hash mapping the node id to a hash containing the resolved facts.
  def to_hash
    fetch_all.value
  end
end
