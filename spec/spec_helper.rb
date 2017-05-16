require 'rspec'
require 'rfacter/config'

RSpec.shared_context 'mock rfacter configuration' do
  # Define mock objects for top-level RFacter configuration.
  # Simple config values, like the timing setting, are configured
  # to return default values.
  let(:config) { instance_double('RFacter::Config::Settings') }
  let(:logger) { instance_double('RFacter::Util::Logger') }

  before(:each) do
    allow(RFacter::Config).to receive(:config).and_return(config)
    allow(config).to receive(:logger).and_return(logger)
    allow(config).to receive(:timing).and_return(false)
  end
end
