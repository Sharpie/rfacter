require 'concurrent'

require 'rfacter'
require_relative '../config'

# Facter compatibility layer
#
# This module exists to provide compatibility shims for Facter DSL methods as
# exposed by the Facter 3.0 Ruby API. Any fact source code that is executed
# within the {RFacter::Util} namespace via `instance_eval` should pick up on
# these shims. The methods in this module should never be called directly.
#
# However, lexical scope is a tricky thing, so "should" is the operative word
# here.
#
# @see https://github.com/puppetlabs/facter/blob/master/Extensibility.md
#
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

  # Shims for top-level Facter methods
  #
  # @todo Implement `[]`
  # @todo Implement `clear`
  # @todo Implement `define_fact`
  # @todo Implement `each`
  # @todo Implement `fact`
  # @todo Implement `flush`
  # @todo Implement `list`
  # @todo Implement `loadfacts`
  # @todo Implement `reset`
  # @todo Implement `search`
  # @todo Implement `search_path`
  # @todo Implement `to_hash`
  # @todo Implement `value`
  # @todo Implement `version`
  module Facter
    # TODO: Implement []
    #
    # Shim for Facter.add(...)
    def self.add(name, options = {}, &block)
      COLLECTION.value.add(name, options, &block)
    end

    def self.debug(msg)
      ::RFacter::Config.config.logger.debug(msg)
    end

    def self.debugonce(msg)
      ::RFacter::Config.config.logger.debugonce(msg)
    end

    def self.log_exception(exception, message = nil)
      ::RFacter::Config.config.logger.log_exception(exception, messge)
    end

    def self.warn(msg)
      ::RFacter::Config.config.logger.warn(msg)
    end

    def self.warnonce(msg)
      ::RFacter::Config.config.logger.warnonce(msg)
    end

    # Facter::Core DSL methods
    #
    # @todo Implement Facter::Core::Aggregate
    module Core
      # Shims for Facter::Core::Exection methods
      #
      # @todo Implement which
      # @todo Impletement ExecutionFailure (just a subclass of StandardError)
      # @todo Implement execution options
      module Execution
        def self.exec(command)
          execute(command, :on_fail => nil)
        end

        def self.execute(command, options = {})
          NODE.value.execute(command).stdout.chomp
        end
      end
    end

    # Facter::Util DSL methods
    #
    # @todo Implement Facter::Util::Resolution
    # @todo Implement Facter::Util::Fact
    module Util
    end
  end
end
