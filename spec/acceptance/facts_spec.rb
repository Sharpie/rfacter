require 'spec_helper_acceptance'

require 'cgi'
require 'pp'

require 'rfacter/node'
require 'rfacter/util/collection'

describe RFacter do
  before(:all) do
    collection = RFacter::Util::Collection.new
    collection.load_all
    @facts = hosts.inject(Hash.new) do |hash, host|
      config = host.host_hash
      ip = config[:ip]
      username = config[:user]
      port = config[:port]
      password = config[:ssh][:password]

      node = RFacter::Node.new("ssh://#{username}:#{CGI.escape(password)}@#{ip}:#{port}")

      # NOTE: Get hostname from Beaker host since these will all be sharing the
      # same IP address.
      hash[host.hostname] = collection.to_hash(node)
      collection.flush

      hash
    end
  end

  it 'collects facts from remote nodes' do
    hosts.each do |host|
      expect(@facts).to include(host.hostname)
    end

    puts PP.pp(@facts, '')
  end
end
