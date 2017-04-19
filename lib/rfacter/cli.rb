require 'rfacter'

require_relative 'config'

module RFacter::CLI
  def self.run(argv)
    args = RFacter::Config.configure_from_argv!(argv)

    exit 0
  end
end
