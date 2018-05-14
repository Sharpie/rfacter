require 'spec_helper_acceptance'

require 'cgi'

require 'rfacter/node'
require 'rfacter/factset'

describe RFacter do
  before(:all) do
    nodes = hosts.map do |host|
              config = host.host_hash
              ip = config[:ip] || host.ip
              username = config[:user]
              port = config[:port]

              host_uri = if host.platform.match(/^windows/)
                           # Update admin password.
                           on(host, 'cmd.exe /c net user Administrator "RF@cter!"')
                           "winrm://#{username}:#{CGI.escape('RF@cter!')}@#{ip}"
                         else
                            password = config[:ssh][:password]
                            "ssh://#{username}:#{CGI.escape(password)}@#{ip}:#{port}"
                         end

              RFacter::Node.new(host_uri,
                # NOTE: Get hostname from Beaker host since these will all be sharing
                # the same IP address.
                id: host.hostname)
            end

    factset = RFacter::Factset.new(nodes)
    @facts = factset.to_hash
  end

  hosts.each do |host|
    context "when collecting facts from #{host.hostname} (#{host.platform})" do
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

        it do
          expect(@facts[host.hostname]).to match(
            a_hash_including('os' => a_hash_including(
            'family' => 'windows')))
        end if host.platform.match(/^windows/)
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

        it do
          expect(@facts[host.hostname]).to match(
            a_hash_including('os' => a_hash_including(
            'name' => 'windows')))
        end if host.platform.match(/^windows/)
      end # os.name examples

      describe('resolving os.architecture') do
        it do
          os_expectation = if host.platform.match(/^windows/)
                             {'architecture' => 'x64',
                              'hardware' => 'x86_64'}
                           else
                             {'architecture' => 'x86_64',
                              'hardware' => 'x86_64'}
                           end

          expect(@facts[host.hostname]).to match(
            a_hash_including('os' => a_hash_including(os_expectation)))
        end if [/-x86_64$/].any? {|regex| regex.match(host.platform)}

        it do
          expect(@facts[host.hostname]).to match(
            a_hash_including('os' => a_hash_including(
              'architecture' => 'amd64',
              'hardware' => 'x86_64')))
        end if [/-amd64$/].any? {|regex| regex.match(host.platform)}

        it do
          os_expectation = if host.platform.match(/^windows/)
                             {'architecture' => 'x86',
                              'hardware' => 'i686'}
                           else
                             {'architecture' => 'i386',
                              'hardware' => 'i386'}
                           end

          expect(@facts[host.hostname]).to match(
            a_hash_including('os' => a_hash_including(os_expectation)))
        end if [/-i386$/].any? {|regex| regex.match(host.platform)}
      end
    end
  end
end
