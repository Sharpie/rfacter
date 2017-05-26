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
# @api public
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
  # @return [String]
  attr_reader :id

  attr_reader :transport

  # Returns a new instance of Node
  #
  # @param uri [URI] The URI of the node.
  # @param id [String, nil] An optional string to use when identifying
  #   this node.
  def initialize(uri, id: nil, config: RFacter::Config.config, **opts)
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

    @id = unless id.nil?
            id
          else
            # Create a default from the URI, minus the password and options
            # components.
            id_string = "#{@scheme}://"
            id_string += "#{@user}@" unless @user.nil?
            id_string += @hostname
            id_string += ":#{@port}" unless @port.nil?
            id_string
          end

    @id.freeze

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

  # Interact with remote files in a read-only manner
  #
  # This method returns an object that can povide read only access to the stats
  # and content of a particular file path.
  #
  # @param path [String] The file path to interact with.
  #
  # @return [Train::Extras::FileCommon] An object representing the remote file.
  def file(path)
    connection.file(path)
  end
end


# Hello dear reader. Hiding at the bottom of this file is a consequence of bad
# design decisions in Ruby --- specifically the Kernel.autoload feature. Train
# uses autload to lazily require its subcomponents. However, autoload plays
# filthy tricks with the resolution of Constants that are not thread-safe. So,
# this chunk of code is sitting down here out of sight to force these autoloads
# to be resolved up front so that we can get on with the business of actually
# saving significant time by using parallelism.
#
# See:
#   http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-core/41149
#   http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-core/20238
#
# TODO: Remove if this PR lands:
#   https://github.com/chef/train/pull/178
require 'train/plugins/transport'
require 'train/plugins/base_connection'

require 'train/transports/ssh'
require 'train/transports/ssh_connection'
require 'train/transports/winrm'
require 'train/transports/winrm_connection'
require 'train/transports/local'
require 'train/transports/local_file'
require 'train/transports/local_os'

require 'train/extras'
require 'train/extras/command_wrapper'
require 'train/extras/file_common'
require 'train/extras/file_unix'
require 'train/extras/file_aix'
require 'train/extras/file_linux'
require 'train/extras/file_windows'
require 'train/extras/os_common'
require 'train/extras/stat'
