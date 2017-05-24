require 'rfacter/node'
require 'rfacter/factset'

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
factset = RFacter::Factset.new(nodes)

fact_data = factset.to_hash.value

puts PP.pp(fact_data, '')
