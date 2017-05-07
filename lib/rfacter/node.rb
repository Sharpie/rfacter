require 'uri'
require 'cgi'
require 'forwardable'

require 'rfacter'
require_relative 'config'

require 'train'
require 'concurrent'

# Interface to a local or remote host
#
# @note This class should be refacter to provide an abstracted interface to
#   different transport backends like Train, Vagrant, Chloride, etc.
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

  # FIXME: For some reason, Train's connection re-use logic isn't working, so a
  # new connection is being negotiated for each command. File a bug.
  #
  # TODO: Ensure connection use is thread-safe.
  def connection
    @connection ||= @transport.connection
  end

  # Execute a command on the node asynchronously
  #
  # This method initiates the execution of a command line and returns an
  # object representing the result.
  #
  # @param command [String] The command string to execute.
  #
  # @return [Train::Extras::CommandResult] The result of the command including
  #   stdout, stderr and exit code.
  #
  # @todo Add support for setting user accounts and environment variables.
  def execute(command)
    connection.run_command(command)
  end

  # Determine if an executable exists and return the path
  #
  # @param executable [String] The executable to locate.
  #
  # @return [String] The path to the executable if it exists.
  #
  # @return [nil] Returned when no matching executable can be located.
  #
  # @todo Add support for setting user accounts and environment variables.
  def which(executable)
    # TODO: Abstract away from the Train "os" implementation.
    result = if connection.os.windows?
      connection.run_command("(Get-Command -TotalCount 1 #{executable}).Path")
    else
      connection.run_command("which #{executable}")
    end

    if (result.exit_status != 0) || (result.stdout.chomp.empty?)
      nil
    else
      result.stdout.chomp
    end
  end
end
