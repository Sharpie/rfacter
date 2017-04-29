require 'concurrent'

require 'rfacter'

# Facter compatibility layer
#
# This module exists to provide compatibility shims for facter DSL methods.
# Any fact source code that is executed within the {RFacter::Util} namespace
# via `instance_eval` should pick up on these shims. The methods in this module
# should never be called directly, and many will raise errors.
#
# However, lexical scope is a tricky thing, so "should" is the operative word
# here.
#
# @private
# @since 0.1.0
module RFacter::Util::DSL
  COLLECTION = Concurrent::ThreadLocalVar.new do
    # If unset, something attempted to use a Facter DSL method that manipulates
    # the fact collection without setting COLLECTION to an instance of
    # RFacter::Util::Collection.
    raise(NameError,<<-EOS)
A Facter DSL method that manipulates a fact collection was called without the
collection being set. This usually happens if the DSL method is called directly
instead of via an instance of Facter::Util::Collection.
EOS
  end

  module Facter
    # Shim for Facter.add(...)
    def self.add(name, options = {}, &block)
      COLLECTION.value.add(name, options, &block)
    end
  end
end
