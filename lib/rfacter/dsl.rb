require 'concurrent'

require 'rfacter'
require_relative 'config'
require_relative 'util/non_nullable'

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
module RFacter::DSL
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

  # DSL for top-level Facter methods
  #
  # @todo Implement `reset`
  # @todo Implement `search`
  module Facter
    # Returns a fact object by name.
    #
    # If you use this, you still have to call
    # {RFacter::Util::Fact#value `value`} on it to retrieve the actual value.
    #
    # @param name [String, Symbol] the name of the fact
    #
    # @return [RFacter::Util::Fact, nil] The fact object, or nil if no fact
    #   is found.
    def self.[](name)
      COLLECTION.value.fact(name)
    end

    # Adds a {RFacter::Util::Resolution resolution} mechanism for a named
    # fact. This does not distinguish between adding a new fact and adding
    # a new way to resolve a fact.
    #
    # @overload add(name, options = {}, { || ... })
    # @param name [String] the fact name
    # @param options [Hash] optional parameters for the fact - attributes
    #   of {RFacter::Util::Fact} and {Facter::Util::Resolution} can be
    #   supplied here
    # @option options [Integer] :timeout set the
    #   {RFacter::Util::Resolution#timeout timeout} for this resolution
    # @param block [Proc] a block defining a fact resolution
    #
    # @return [RFacter::Util::Fact] the fact object, which includes any previously
    #   defined resolutions
    def self.add(name, options = {}, &block)
      COLLECTION.value.add(name, options, &block)
    end

    # Clears all cached values and removes all facts from memory.
    #
    # @return [void]
    def self.clear
      self.flush
      self.reset
    end

    # Prints a debug message if debugging is turned on
    #
    # @param msg [String] the debug message
    #
    # @return [void]
    def self.debug(msg)
      ::RFacter::Config.config.logger.debug(msg)
    end

    # Prints a debug message only once.
    #
    # @note Uniqueness is based on the string, not the specific location
    #   of the method call.
    #
    # @param msg [String] the debug message
    # @return [void]
    def self.debugonce(msg)
      ::RFacter::Config.config.logger.debugonce(msg)
    end

    # Define a new fact or extend an existing fact.
    #
    # @param name [Symbol] The name of the fact to define
    # @param options [Hash] A hash of options to set on the fact
    #
    # @return [RFacter::Util::Fact] The fact that was defined
    #
    # @see {RFacter::Util::Collection#define_fact}
    def self.define_fact(name, options = {}, &block)
      COLLECTION.value.define_fact(name, options, &block)
    end

    # Iterates over fact names and values
    #
    # @yieldparam [String] name the fact name
    # @yieldparam [String] value the current value of the fact
    #
    # @return [void]
    def self.each
      COLLECTION.value.each do |*args|
        yield(*args)
      end
    end

    # (see [])
    def self.fact(name)
      COLLECTION.value.fact(name)
    end

    # Flushes cached values for all facts. This does not cause code to be
    # reloaded; it only clears the cached results.
    #
    # @return [void]
    def self.flush
      COLLECTION.value.flush
    end

    # Lists all fact names
    #
    # @return [Array<String>] array of fact names
    def self.list
      COLLECTION.value.list
    end

    # Loads all facts.
    #
    # @return [void]
    def self.loadfacts
      COLLECTION.value.load_all
    end

    def self.log_exception(exception, message = nil)
      ::RFacter::Config.config.logger.log_exception(exception, messge)
    end

    # Removes all facts from memory. Use this when the fact code has
    # changed on disk and needs to be reloaded.
    #
    # @note This is currently a no-op for RFacter pending changes to how
    #   collections are handled.
    #
    # @return [void]
    def self.reset
    end

    # Register directories to be searched for facts. The registered directories
    # must be absolute paths or they will be ignored.
    #
    # @param dirs [String] directories to search
    #
    # @note This is currently a no-op for RFacter pending changes to how
    #   collections are handled.
    #
    # @return [void]
    def self.search(*dirs)
    end

    # Returns the registered search directories.
    #
    # @return [Array<String>] An array of the directories searched
    def self.search_path
      COLLECTION.value.search_path
    end

    # Gets a hash mapping fact names to their values.
    #
    # @return [Hash{String => Object}] the hash of fact names and values
    def self.to_hash
      COLLECTION.value.to_hash(NODE.value)
    end

    # Gets the value for a fact.
    #
    # @param name [String, Symbol] the fact name
    #
    # @return [Object, nil] the value of the fact, or nil if no fact is
    #   found
    def self.value(name)
      COLLECTION.value.value(name, NODE.value)
    end

    # Returns the current RFacter version
    #
    # @return [String]
    def self.version
      RFacter::VERSION
    end

    # Prints a warning message. The message is only printed if debugging
    # is enabled.
    #
    # @param msg [String] the warning message to be printed
    #
    # @return [void]
    def self.warn(msg)
      ::RFacter::Config.config.logger.warn(msg)
    end


    # Prints a warning message only once per process. Each unique string
    # is printed once.
    #
    # @note Unlike {warn} the message will be printed even if debugging is
    #   not turned on. This behavior is likely to change and should not be
    #   relied on.
    #
    # @param msg [String] the warning message to be printed
    #
    # @return [void]
    def self.warnonce(msg)
      ::RFacter::Config.config.logger.warnonce(msg)
    end

    # Facter::Core DSL methods
    module Core
      require_relative 'core/aggregate'
      # (see RFacter::Core::Aggregate)
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
              raise ::RFacter::DSL::Facter::Core::Execution::ExecutionFailure.new,
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
      require_relative 'util/fact'
      # (see RFacter::Util::Fact)
      Fact = ::RFacter::Util::Fact

      require_relative 'util/resolution'
      # (see RFacter::Util::Resolution)
      Resolution = ::RFacter::Util::Resolution

      # Methods for interacting with remote files.
      #
      # @note The `exists?` part is uniqe to RFacter.
      #
      # @todo Possibly augment this with some top-level shims for File?
      module FileRead
        def self.read(path)
          NODE.value.file(path).content
        end

        def self.exists?(path)
          NODE.value.file(path).exist?
        end
      end
    end
  end
end
