require 'pathname'
require 'forwardable'

require 'rfacter'
require_relative '../config'
require_relative '../dsl'

# Load facts on demand.
#
# @api private
# @since 0.1.0
class RFacter::Util::Loader
  extend Forwardable

  instance_delegate([:logger] => :@config)

  def initialize(config: RFacter::Config.config, **opts)
    @config = config
    @loaded = []
  end

  # Load all resolutions for a single fact.
  #
  # @param fact [Symbol]
  def load(fact, collection)
    # Now load from the search path
    shortname = fact.to_s.downcase

    filename = shortname + ".rb"

    paths = search_path
    unless paths.nil?
      paths.each do |dir|
        # Load individual files
        file = File.join(dir, filename)

        load_file(file, collection) if File.file?(file)
      end
    end
  end

  # Load all facts from all directories.
  def load_all(collection)
    return if defined?(@loaded_all)

    paths = search_path
    unless paths.nil?
      paths.each do |dir|
        # dir is already an absolute path
        Dir.glob(File.join(dir, '*.rb')).each do |path|
          # exclude dirs that end with .rb
          load_file(path, collection) if File.file?(path)
        end
      end
    end

    @loaded_all = true
  end

  # List directories to search for fact files.
  #
  # Search paths are gathered from the following sources:
  #
  # 1. A core set of facts from the rfacter/facts directory
  # 2. ENV['RFACTERLIB'] is split and used verbatim
  #
  # A warning will be generated for paths that are not
  # absolute directories.
  #
  # @return [Array<String>]
  def search_path
    search_paths = [File.expand_path('../../facts', __FILE__)]

    if ENV.include?("RFACTERLIB")
      search_paths += ENV["RFACTERLIB"].split(File::PATH_SEPARATOR)
    end

    search_paths.delete_if { |path| ! valid_search_path?(path) }

    search_paths.uniq
  end

  # Validate that the given path is valid, ie it is an absolute path.
  #
  # @param path [String]
  # @return [Boolean]
  def valid_search_path?(path)
    Pathname.new(path).absolute? && File.directory?(path)
  end

  # Load a file and record is paths to prevent duplicate loads.
  #
  # @param file [String] The *absolute path* to the file to load
  def load_file(file, collection)
    return if @loaded.include? file

    # We have to specify Kernel.load, because we have a load method.
    begin
      # Store the file path so we don't try to reload it
      @loaded << file

      RFacter::DSL::COLLECTION.bind(collection) do
        collection.instance_eval(File.read(file), file)
      end
    rescue Exception => detail
      # Don't store the path if the file can't be loaded
      # in case it's loadable later on.
      @loaded.delete(file)
      logger.log_exception(detail, "Error loading fact #{file}: #{detail.message}")
    end
  end
end
