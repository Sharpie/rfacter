require 'concurrent'

require 'rfacter'

# Non-nullable thread local variable
#
# A Subclass of Concurrent::ThreadLocalVar that raises a NameError
# if de-referenced to `nil`. This allows the creation of variables
# that must always be bound to a specific value before use.
#
# @since 0.1.0
class RFacter::Util::NonNullable < Concurrent::ThreadLocalVar
  # @param err_message [String] The error message to raise if
  #   the instance is de-referenced to a `nil` value.
  def initialize(default = nil, err_message:, &default_block)
    @err_message = err_message
    super(default, &default_block)
  end

  # Private reference to the superclass `value` method that won't
  # raise an error. Allows the `bind` method to re-set the variable
  # to nil at the end of an operation.
  alias_method :nillable_value, :value
  private :nillable_value

  def bind(value, &block)
    if block_given?
      old_value = nillable_value
      begin
        self.value = value
        yield
      ensure
        self.value = old_value
      end
    end
  end

  # @raise [NameError] when de-referenced to `nil`.
  def value
    result = super

    raise(NameError, @err_message) if result.nil?

    result
  end
end
