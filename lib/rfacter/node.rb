require 'uri'
require 'cgi'
require 'forwardable'

require 'rfacter'
require_relative 'config'

require 'train'
require 'concurrent'

# Interface to a local or remote host
#
# @note This class should provide an abstract to different transport backends
#   like Train, Vagrant, Chloride, etc.
#
# @since 0.1.0
class RFacter::Node
  extend Forwardable

  instance_delegate([:logger] => :@config)

  # @return [URI]
  attr_reader :uri

  # @return [String]
  attr_reader :hostname
  # @return [String]
  attr_reader :scheme
  # @return [Integer, nil]
  attr_reader :port
  # @return [String, nil]
  attr_reader :user
  # @return [String, nil]
  attr_reader :password
  # @return [Hash]
  attr_reader :options

  attr_reader :transport

  def initialize(uri, config: RFacter::Config.config, **opts)
    @config = config

    @uri = unless uri.is_a?(URI)
      URI.parse(uri.to_s)
    else
      uri
    end

    @hostname = @uri.hostname || @uri.path
    @scheme = if @uri.scheme.nil? && (@hostname == 'localhost')
      'local'
    elsif @uri.scheme.nil?
      'ssh'
    else
      @uri.scheme
    end

    case @scheme
    when 'ssh'
      @port = @uri.port || 22
      @user = @uri.user || 'root'
    when 'winrm'
      @user = @uri.user || 'Administrator'
    end

    @password = CGI.unescape(@uri.password) unless @uri.password.nil?
    @options = @uri.query.nil? ? Hash.new : CGI.parse(@uri.query)
    @options.update(opts)

    # TODO: This should be abstracted.
    @transport = Train.create(@scheme,
      host: @hostname,
      user: @user,
      password: @password,
      port: @port,
      logger: logger, **@options)
  end

  # Execute a command on the node asynchronously
  #
  # This method initiates the execution of a command line and returns a
  # future that can be used to retrieve the result once execution completes.
  # This allows several remote commands to be dispatched and their results
  # collected.
  #
  # @param command [String] The command string to execute.
  #
  # @return [Concurrent::Future] A {Concurrent::Future} that can be used
  #   to access the result of the command.
  def execute(command)
    Concurrent::Future.execute do
      # TODO: Ensure the underlying connection is re-used and re-used in
      # a threadsafe manner.
      @transport.connection.run_command(command)
    end
  end

end
