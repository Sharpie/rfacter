# Fact: networking
#
# Purpose: Return the system's short hostname.
#
# Resolution:
#   On all systems but Darwin, parses the output of the `hostname` system command
#   to everything before the first period.
#   On Darwin, uses the system configuration util to get the LocalHostName
#   variable.
#
# Caveats:
#

Facter.add(:networking, :type => :aggregate) do
  chunk(:hostname) do
    name = Facter::Core::Execution.execute('hostname')

    if name.empty?
      {}
    else
      {'hostname' => name.split('.').first}
    end
  end

  chunk(:domain) do
    return_value = nil

    hostname_command = case Facter.value(:kernel)
                       when /Linux/i, /FreeBSD/i, /Darwin/i
                         'hostname -f 2> /dev/null'
                       else
                         'hostname 2> /dev/null'
                       end

    if name = Facter::Core::Execution.exec(hostname_command) \
        and match = name.match(/.*?\.(.+$)/)

      return_value = match.captures.first
    elsif domain = Facter::Core::Execution.exec('dnsdomainname 2> /dev/null') \
      and domain.match(/.+/)

      return_value = domain
    elsif Facter::Util::FileRead.exists?("/etc/resolv.conf")
      domain = nil
      search = nil
      Facter::Util::FileRead.read('/etc/resolv.conf').lines.each do |line|
        if (match = line.match(/^\s*domain\s+(\S+)/))
          domain = match.captures.first
        elsif (match = line.match(/^\s*search\s+(\S+)/))
          search = match.captures.first
        end
      end
      return_value ||= domain
      return_value ||= search
    end

    if return_value.nil?
      {}
    else
      {'domain' => return_value.gsub(/\.$/, '')}
    end
  end

  chunk(:fqdn, require: [:hostname, :domain]) do |net_hostname, net_domain|
    host = net_hostname['hostname']
    domain = net_domain['domain']

    fqdn = if host && domain
      [host, domain].join(".")
    elsif host
      host
    else
      nil
    end

    if fqdn.nil?
      {}
    else
      {'fqdn' => fqdn}
    end
  end
end

Facter.add(:hostname, :type => :aggregate) do
  confine :kernel => :windows

  chunk(:hostname) do
    name = Facter::Core::Execution.execute('hostname')

    if name.empty?
      {}
    else
      {'hostname' => name.split('.').first}
    end
  end

  chunk(:domain) do
    return_value = nil

    network_info = Facter::Core::Execution.execute(<<-PS1)
(Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Property DNSDomain -Filter 'IPEnabled = True'|
  Select-Object -First 1).DNSDomain
PS1

    if network_info.empty?
      {}
    else
      {'domain' => network_info.strip}
    end
  end

  chunk(:fqdn, require: [:hostname, :domain]) do |net_hostname, net_domain|
    host = net_hostname['hostname']
    domain = net_domain['domain']

    fqdn = if host && domain
      [host, domain].join(".")
    elsif host
      host
    else
      nil
    end

    if fqdn.nil?
      {}
    else
      {'fqdn' => fqdn}
    end
  end
end
