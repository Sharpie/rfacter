require 'rfacter/node'
require 'rfacter/util/collection'

require 'pp' # For pretty-printing

# Nodes are specified using a URL string which can include:
#
#   - The transport scheme to use: SSH, WinRM, or local
#   - The username and password to use. SSH will use keys from ssh-agent if
#     available and password isn't set.
#   - The hostname to connect to.
#   - The port to use.
node_urls = [
  # Executes commands directly on the local machine
  'localhost',
  # Defaults to ssh with the root user account.
  'some.box.running.ssh.example',
  'ssh://user@some.box.running.ssh.example',
  # Special characters in passwords should be %-encoded.
  'winrm://Administrator:P%40ssword@some.windows.box.example'
]

nodes = node_urls.map {|u| RFacter::Node.new(u) }

facts = RFacter::Util::Collection.new
facts.load_all # Load all fact definitions

fact_data = nodes.inject(Hash.new) do |hash, node|
  hash[node.hostname] = facts.to_hash(node)
  # Flush is needed for now to clear values cached by the Collection class so
  # that a different node can be looked up. This requirement will go away when
  # the caching layer is updated to be node-aware.
  facts.flush

  hash
end

puts PP.pp(fact_data, '')
