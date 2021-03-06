require 'forwardable'

require 'rfacter'
require_relative '../config'

# This represents a fact resolution. A resolution is a concrete
# implementation of a fact. A single fact can have many resolutions and
# the correct resolution will be chosen at runtime. Each time
# {RFacter::DSL::Facter.add Facter.add} is called, a new resolution is created
# and added to the set of resolutions for the fact named in the call.  Each
# resolution has a {#has_weight weight}, which defines its priority over other
# resolutions, and a set of {#confine _confinements_}, which defines the
# conditions under which it will be chosen. All confinements must be satisfied
# for a fact to be considered _suitable_.
#
# @api private
# @since 0.1.0
class RFacter::Util::Resolution
  require_relative '../dsl'
  require_relative '../core/resolvable'
  require_relative '../core/suitable'
  extend Forwardable

  instance_delegate([:logger] => :@config)

  attr_accessor :code
  attr_writer :value

  include RFacter::Core::Resolvable
  include RFacter::Core::Suitable

  # @!attribute [rw] name
  # The name of this resolution. The resolution name should be unique with
  # respect to the given fact.
  # @return [String]
  attr_accessor :name

  # @!attribute [r] fact
  # @return [RFacter::Util::Fact]
  attr_reader :fact

  def which(command)
    ::RFacter::DSL::Facter::Core::Execution.which(command)
  end

  def exec(command)
    ::RFacter::DSL::Facter::Core::Execution.exec(command)
  end

  # Create a new resolution mechanism.
  #
  # @param name [String] The name of the resolution.
  # @return [void]
  def initialize(name, fact, config: RFacter::Config.config, **options)
    @name = name
    @fact = fact
    @config = config
    @confines = []
    @value = nil
    @timeout = 0
    @weight = nil
  end

  def resolution_type
    :simple
  end

  # Evaluate the given block in the context of this resolution. If a block has
  # already been evaluated emit a warning to that effect.
  #
  # @return [void]
  def evaluate(&block)
    if @last_evaluated
      msg = "Already evaluated #{@name}"
      msg << " at #{@last_evaluated}" if msg.is_a? String
      msg << ", reevaluating anyways"
      logger.warn msg
    end

    instance_eval(&block)

    @last_evaluated = block.source_location.join(':')
  end

  def set_options(options)
    if options[:name]
      @name = options.delete(:name)
    end

    if options.has_key?(:value)
      @value = options.delete(:value)
    end

    if options.has_key?(:timeout)
      @timeout = options.delete(:timeout)
    end

    if options.has_key?(:weight)
      @weight = options.delete(:weight)
    end

    if not options.keys.empty?
      raise ArgumentError, "Invalid resolution options #{options.keys.inspect}"
    end
  end

  # Sets the code block or external program that will be evaluated to
  # get the value of the fact.
  #
  # @return [void]
  #
  # @overload setcode(string)
  #   Sets an external program to call to get the value of the resolution
  #   @param [String] string the external program to run to get the
  #     value
  #
  # @overload setcode(&block)
  #   Sets the resolution's value by evaluating a block at runtime
  #   @param [Proc] block The block to determine the resolution's value.
  #     This block is run when the fact is evaluated. Errors raised from
  #     inside the block are rescued and printed to stderr.
  def setcode(string = nil, &block)
    if string
      @code = Proc.new do
        output = exec(string)
        if output.nil? or output.empty?
          nil
        else
          output
        end
      end
    elsif block_given?
      @code = block
    else
      raise ArgumentError, "You must pass either code or a block"
    end
  end

  private

  def resolve_value
    if @value
      @value
    elsif @code.nil?
      nil
    elsif @code
      @code.call()
    end
  end
end
