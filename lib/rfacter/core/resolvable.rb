require 'timeout'

require 'rfacter'
require_relative '../util/normalization'

# The resolvable mixin defines behavior for evaluating and returning fact
# resolutions.
#
# Classes including this mixin should implement at #name method describing
# the value being resolved and a #resolve_value that actually executes the code
# to resolve the value.
#
# @api private
# @since 0.1.0
module RFacter::Core::Resolvable

  # The timeout, in seconds, for evaluating this resolution.
  # @return [Integer]
  # @api public
  attr_accessor :timeout

  # Return the timeout period for resolving a value.
  # (see #timeout)
  # @return [Numeric]
  def limit
    # requiring 'timeout' stdlib class causes Object#timeout to be defined
    # which delegates to Timeout.timeout. This method may potentially overwrite
    # the #timeout attr_reader on this class, so we define #limit to avoid
    # conflicts.
    @timeout || 0
  end

  ##
  # on_flush accepts a block and executes the block when the resolution's value
  # is flushed.  This makes it possible to model a single, expensive system
  # call inside of a Ruby object and then define multiple dynamic facts which
  # resolve by sending messages to the model instance.  If one of the dynamic
  # facts is flushed then it can, in turn, flush the data stored in the model
  # instance to keep all of the dynamic facts in sync without making multiple,
  # expensive, system calls.
  #
  # Please see the Solaris zones fact for an example of how this feature may be
  # used.
  #
  # @see RFacter::Util::Fact#flush
  #
  # @api public
  def on_flush(&block)
    @on_flush_block = block
  end

  ##
  # flush executes the block, if any, stored by the {#on_flush} method
  #
  # @see RFacter::Util::Fact#flush
  #
  # @api private
  def flush
    @on_flush_block.call if @on_flush_block
  end

  def value
    result = nil

    with_timing do
      Timeout.timeout(limit) do
        result = resolve_value
      end
    end

    RFacter::Util::Normalization.normalize(result)
  rescue Timeout::Error => detail
   logger.log_exception(detail, "Timed out after #{limit} seconds while resolving #{qualified_name}")
    return nil
  rescue RFacter::Util::Normalization::NormalizationError => detail
   logger.log_exception(detail, "Fact resolution #{qualified_name} resolved to an invalid value: #{detail.message}")
    return nil
  rescue => detail
   logger.log_exception(detail, "Could not retrieve #{qualified_name}: #{detail.message}")
    return nil
  end

  private

  def with_timing
    unless @config.profile
      yield
    else
      starttime = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
      yield
      finishtime = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)

      elapsed = (finishtime - starttime)
      logger.info { "#{qualified_name}: #{"%.2f" % elapsed}ms" }
    end
  end

  def qualified_name
    "fact='#{@fact.name.to_s}', resolution='#{@name || '<anonymous>'}'"
  end
end
