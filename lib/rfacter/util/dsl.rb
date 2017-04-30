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
# @see https://github.com/puppetlabs/facter/blob/master/Extensibility.md
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
instead of via an instance of RFacter::Util::Collection.
EOS
  end

  NODE = Concurrent::ThreadLocalVar.new do
    # If unset, something attempted to use a Facter DSL method that shells
    # out for imformation without setting NODE to an instance of
    # RFacter::Node.
    raise(NameError,<<-EOS)
A Facter DSL method that executes shell commands was called without a
node to execute on being set. This usually happens if the DSL method is called
directly instead of via an instance of RFacter::Util::Collection.
EOS
  end

  module Facter
    # Shim for Facter.add(...)
    def self.add(name, options = {}, &block)
      COLLECTION.value.add(name, options, &block)
    end

    module Core
      module Execution
        # TODO: Implement which
        # TODO: Impletement ExecutionFailure (just a subclass of StandardError)
        # TODO: Implement execution options

        def self.exec(command)
          execute(command, :on_fail => nil)
        end

        def self.execute(command, options = {})
          NODE.value.execute(command).stdout.chomp
        end
      end
    end
  end
end
