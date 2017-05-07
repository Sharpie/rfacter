require 'concurrent'

require 'rfacter'
require_relative '../config'
require_relative 'non_nullable'

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
# @api public
# @since 0.1.0
module RFacter::Util::DSL
  # FIXME: Add i18n for the following.
  COLLECTION = RFacter::Util::NonNullable.new(err_message: <<-EOS)
A Facter DSL method that manipulates a fact collection was called without the
collection being set. This usually happens if the DSL method is called directly
instead of via an instance of RFacter::Util::Collection.
EOS

  NODE = RFacter::Util::NonNullable.new(err_message: <<-EOS)
A Facter DSL method that executes shell commands was called without a
node to execute on being set. This usually happens if the DSL method is called
directly instead of via an instance of RFacter::Util::Collection.
EOS

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
    module Core
      require_relative '../core/aggregate'
      Aggregate = ::RFacter::Core::Aggregate

      # Shims for Facter::Core::Exection methods
      #
      # @todo Implement execution options
      module Execution
        # Error raised when :on_fail is set
        class ExecutionFailure < StandardError; end

        # Try to execute a command and return the output.
        #
        # @param code [String] the program to run
        #
        # @return [String] the output of the program, or nil if the command
        #   does not exist or could not be executed.
        #
        # @deprecated Use #{execute} instead
        def self.exec(command)
          execute(command, on_fail: nil)
        end

        # Execute a command and return the output of that program.
        #
        # @param code [String] the program to run
        # @param options [Hash]
        #
        # @option options [Object] :on_fail How to behave when the command
        #   could not be run. Specifying `:raise` will raise an error, anything
        #   else will return that object on failure. Default is `:raise`.
        #
        # @raise [RFacter::Util::DSL::Facter::Core::Execution::ExecutionFailure]
        #   If the command does not exist or could not be executed.
        #
        # @return [String] The stdout of the program.
        #
        # @return [Object] The value of `:on_fail` if command execution failed
        #   and `:on_fail` was specified.
        def self.execute(command, on_fail: :raise, **options)
          begin
            output = NODE.value.execute(command).stdout.chomp
          rescue => detail
            if on_fail == :raise
              raise ::RFacter::Util::DSL::Facter::Core::Execution::ExecutionFailure.new,
                "Failed while executing '#{command}': #{detail.message}"
            else
              return on_fail
            end
          end

          output
        end

        # Determines the full path to a binary.
        #
        # Returns nil if no matching executable can be found otherwise returns
        # the expanded pathname.
        #
        # @param bin [String] the executable to locate
        #
        # @return [String,nil] the full path to the executable or nil if not
        #   found
        def self.which(bin)
          NODE.value.which(bin)
        end
      end
    end

    # Facter::Util DSL methods
    module Util
      require_relative 'fact'
      Fact = ::RFacter::Util::Fact

      require_relative 'resolution'
      Resolution = ::RFacter::Util::Resolution
    end
  end
end
