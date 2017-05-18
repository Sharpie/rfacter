require 'forwardable'

require 'rfacter'
require_relative '../config'
require_relative '../dsl'
require_relative 'loader'
require_relative 'fact'

# Manage which facts exist on a Node and how we access them.
#
# Largely just a wrapper around a hash of facts that have been retrieved from a
# particular node.
#
# @api private
# @since 0.1.0
class RFacter::Util::Collection
  # Ensures unqualified namespaces like `Facter` and `Facter::Util` get
  # re-directed to RFacter shims when the loader calls `instance_eval`
  include RFacter::DSL
  extend Forwardable

  instance_delegate([:logger] => :@config)

  # Initialize a new Collection object
  #
  # @param node [RFacter::Node] The node from which this collection
  #   should retrieve facts.
  def initialize(node, config: RFacter::Config.config, **opts)
    @node = node
    @config = config

    @facts = Hash.new
    @internal_loader = RFacter::Util::Loader.new
  end

  # Return a fact object by name.
  def [](name)
    value(name)
  end

  # Define a new fact or extend an existing fact.
  #
  # @param name [Symbol] The name of the fact to define
  # @param options [Hash] A hash of options to set on the fact
  #
  # @return [RFacter::Util::Fact] The fact that was defined
  def define_fact(name, options = {}, &block)
    fact = create_or_return_fact(name, options)

    if block_given?
      fact.instance_eval(&block)
    end

    fact
  rescue => e
    logger.log_exception(e, "Unable to add fact #{name}: #{e}")
  end

  # Add a resolution mechanism for a named fact.  This does not distinguish
  # between adding a new fact and adding a new way to resolve a fact.
  #
  # @param name [Symbol] The name of the fact to define
  # @param options [Hash] A hash of options to set on the fact and resolution
  #
  # @return [RFacter::Util::Fact] The fact that was defined
  def add(name, options = {}, &block)
    fact = create_or_return_fact(name, options)

    fact.add(options, &block)

    return fact
  end

  include Enumerable

  # Iterate across all of the facts.
  def each
    load_all

    RFacter::DSL::COLLECTION.bind(self) do
      RFacter::DSL::NODE.bind(@node) do
        @facts.each do |name, fact|
          value = fact.value
          unless value.nil?
            yield name.to_s, value
          end
        end
      end
    end
  end

  # Return a fact by name.
  def fact(name)
    name = canonicalize(name)

    # Try to load the fact if necessary
    load(name) unless @facts[name]

    # Try HARDER
    load_all unless @facts[name]

    if @facts.empty?
      logger.warnonce("No facts loaded from #{@internal_loader.search_path.join(File::PATH_SEPARATOR)}")
    end

    @facts[name]
  end

  # Flush all cached values.
  def flush
    @facts.each { |name, fact| fact.flush }
  end

  # Return a list of all of the facts.
  def list
    load_all
    return @facts.keys
  end

  def load(name)
    @internal_loader.load(name, self)
  end

  # Load all known facts.
  def load_all
    @internal_loader.load_all(self)
  end

  # Return a hash of all of our facts.
  def to_hash
    @facts.inject({}) do |h, ary|
      resolved_value = RFacter::DSL::COLLECTION.bind(self) do
        RFacter::DSL::NODE.bind(@node) do
          ary[1].value
        end
      end

      # For backwards compatibility, convert the fact name to a string.
      h[ary[0].to_s] = resolved_value unless resolved_value.nil?

      h
    end
  end

  def value(name)
    RFacter::DSL::COLLECTION.bind(self) do
      RFacter::DSL::NODE.bind(@node) do
        if fact = fact(name)
          fact.value
        end
      end
    end
  end

  private

  def create_or_return_fact(name, options)
    name = canonicalize(name)

    fact = @facts[name]

    if fact.nil?
      fact = RFacter::Util::Fact.new(name, options)
      @facts[name] = fact
    end

    fact
  end

  def canonicalize(name)
    name.to_s.downcase.to_sym
  end
end
