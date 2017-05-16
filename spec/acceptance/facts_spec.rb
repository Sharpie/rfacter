require 'spec_helper_acceptance'

require 'cgi'

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

  hosts.each do |host|
    context "when collecting facts from #{host.hostname}" do
      # The testcases below are assembled by matching the host platform against
      # beaker platofrm specifications and the host hostname against
      # beaker-hostgenerator platform strings.
      context('resolving os.family') do
        it do
          expect(@facts[host.hostname]).to match(
            a_hash_including('os' => a_hash_including(
            'family' => 'RedHat')))
        end if [/^el-/, /^centos-/, /^redhat-/, /^oracle-/, /^scientific-/, /^fedora-/].any? {|regex| regex.match(host.platform)}

        it do
          expect(@facts[host.hostname]).to match(
            a_hash_including('os' => a_hash_including(
            'family' => 'Suse')))
        end if [/^sles-/, /^opensuse/].any? {|regex| regex.match(host.platform)}

        it do
          expect(@facts[host.hostname]).to match(
            a_hash_including('os' => a_hash_including(
            'family' => 'Debian')))
        end if [/^debian-/, /^ubuntu/].any? {|regex| regex.match(host.platform)}
      end # os.family examples


      describe('resolving os.name') do
        it do
          expect(@facts[host.hostname]).to match(
            a_hash_including('os' => a_hash_including(
            'name' => 'Fedora')))
        end if [/^fedora\d+/].any? {|regex| regex.match(host.hostname)}

        it do
          expect(@facts[host.hostname]).to match(
            a_hash_including('os' => a_hash_including(
            'name' => 'RedHat')))
        end  if [/^redhat\d+/].any? {|regex| regex.match(host.hostname)}

        it do
          expect(@facts[host.hostname]).to match(
            a_hash_including('os' => a_hash_including(
            'name' => 'CentOS')))
        end  if [/^centos\d+/].any? {|regex| regex.match(host.hostname)}

        it do
          expect(@facts[host.hostname]).to match(
            a_hash_including('os' => a_hash_including(
            'name' => 'OracleLinux')))
        end if [/^oracle\d+/].any? {|regex| regex.match(host.hostname)}


        it do
          expect(@facts[host.hostname]).to match(
            a_hash_including('os' => a_hash_including(
            'name' => 'Debian')))
        end if [/^debian\d+/].any? {|regex| regex.match(host.hostname)}

        it do
          expect(@facts[host.hostname]).to match(
            a_hash_including('os' => a_hash_including(
            'name' => 'Ubuntu')))
        end if [/^ubuntu\d+/].any? {|regex| regex.match(host.hostname)}


        it do
          expect(@facts[host.hostname]).to match(
            a_hash_including('os' => a_hash_including(
            'name' => 'OpenSuSE')))
        end if [/^opensuse\d+/].any? {|regex| regex.match(host.hostname)}

        it do
          expect(@facts[host.hostname]).to match(
            a_hash_including('os' => a_hash_including(
            'name' => 'SLES')))
        end if [/^sles\d+/].any? {|regex| regex.match(host.hostname)}
      end # os.name examples

      describe('resolving os.architecture') do
        it do
          expect(@facts[host.hostname]).to match(
            a_hash_including('os' => a_hash_including(
              'architecture' => 'x86_64',
              'hardware' => 'x86_64')))
        end if [/-x86_64$/].any? {|regex| regex.match(host.platform)}

        it do
          expect(@facts[host.hostname]).to match(
            a_hash_including('os' => a_hash_including(
              'architecture' => 'amd64',
              'hardware' => 'x86_64')))
        end if [/-amd64$/].any? {|regex| regex.match(host.platform)}
      end
    end
  end
end
