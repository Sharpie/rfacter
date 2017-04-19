require 'rfacter'

module RFacter::CLI
  def self.run(args)
    puts "RFacter v#{RFacter::VERSION}"
    puts "Hello, world!"

    exit 0
  end
end
