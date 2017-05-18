Facter.add(:os, :type => :aggregate) do
  chunk(:name) do
    {'name' => Facter.value(:kernel)}
  end

  chunk(:family) do
    {'family' => Facter.value(:kernel)}
  end

  chunk(:architecture) do
    arch = Facter::Core::Execution.execute('uname -m')

    {
      'architecture' => arch,
      'hardware' => arch
    }
  end

  chunk(:release) do
    release_info = {
      'full'  => Facter.value(:kernelrelease),
      'major' => Facter.value(:kernelrelease).split('.')[0],
      'minor' => Facter.value(:kernelrelease).split('.')[1]
    }

    {'release' => release_info.reject{|_, v| v.nil?}}
  end
end

Facter.add(:os, :type => :aggregate) do
  confine :kernel => 'linux'

  chunk(:name) do
    # TODO: Much of this code was imported from facter/operatingsystem/linux.rb
    # from Facter 2.4.6. Facter 3 uses the same sort of logic, but tests files
    # in a different order. Should cross check this to make sure there haven't
    # been important changes to order or additions.

    # NOTE: Can assume that the transport layer caches the results of File
    # stats and reads, so multiple file ops only incur a cost once. However,
    # these ops are all going over the network, so we should probably
    # prioritize RedHat and SuSE detection over less common Linuxen in order to
    # cut down on network chatter that will be useless in most cases.
    operatingsystem = nil

    # Determine OS name from /etc/os-release if it exists.
    #
    # see: https://www.freedesktop.org/software/systemd/man/os-release.html
    if Facter::Util::FileRead.exists?('/etc/os-release')
      os_release = Facter::Util::FileRead.read('/etc/os-release')
      # NOTE: The ID field is used instead of NAME as ID was explicitly
      # designed to be parsed by scripts whereas NAME is for human consumption.
      os_id = os_release.lines.find {|l| l.start_with?('ID=')}

      unless os_id.nil?
        operatingsystem = case os_id
                          when /debian/i
                            'Debian'
                          when /ubuntu/i
                            'Ubuntu'
                          when /opensuse/i
                            'OpenSuSE'
                          when /sles/i
                            'SLES'
                          when /fedora/i
                            'Fedora'
                          when /centos/i
                            'CentOS'
                          when /ol/i
                            'OracleLinux'
                          when /rhel/i
                            'RedHat'
                          when /amzn/i
                            'Amazon'
                          else
                            os_id.scan(/^(?:\w+)=[\"']?(.+?)[\"']?$/).flatten.first
                          end
      end
    end

    if operatingsystem.nil?
      operatingsystem = if Facter.value(:kernel) == "GNU/kFreeBSD"
        "GNU/kFreeBSD"
      elsif Facter::Util::FileRead.exists?('/etc/debian_version')
        case Facter::Core::Execution.exec('lsb_release -i')
        when /Ubuntu/i
          'Ubuntu'
        when /LinuxMint/i
          'LinuxMint'
        else
          'Debian'
        end
      end
    end

    release_files = {
      "AristaEOS"   => "/etc/Eos-release",
      "Debian"      => "/etc/debian_version",
      "Gentoo"      => "/etc/gentoo-release",
      "Fedora"      => "/etc/fedora-release",
      "Mageia"      => "/etc/mageia-release",
      "Mandriva"    => "/etc/mandriva-release",
      "Mandrake"    => "/etc/mandrake-release",
      "MeeGo"       => "/etc/meego-release",
      "Archlinux"   => "/etc/arch-release",
      "Manjarolinux"=> "/etc/manjaro-release",
      "OracleLinux" => "/etc/oracle-release",
      "OpenWrt"     => "/etc/openwrt_release",
      "Alpine"      => "/etc/alpine-release",
      "VMWareESX"   => "/etc/vmware-release",
      "Bluewhite64" => "/etc/bluewhite64-version",
      "Slamd64"     => "/etc/slamd64-version",
      "Slackware"   => "/etc/slackware-version"
    }

    if operatingsystem.nil?
      release_files.each do |os, releasefile|
        if Facter::Util::FileRead.exists?(releasefile)
          operatingsystem = os
          break # Stop sending commands over the network.
        end
      end
    end

    if operatingsystem.nil?
      if Facter::Util::FileRead.exists?('/etc/enterprise-release')
        if Facter::Util::FileRead.exists?('/etc/ovs-release')
          operatingsystem = "OVS"
        else
          operatingsystem = "OEL"
        end
      elsif Facter::Util::FileRead.exists?('/etc/redhat-release')
        operatingsystem = case Facter::Util::FileRead.read('/etc/redhat-release')
        when /CERN/i
          'SLC'
        when /centos/i
          'CentOS'
        when /Scientific/i
          'Scientific'
        when /^cloudlinux/i
          'CloudLinux'
        when /^Parallels Server Bare Metal/
          'PSBM'
        when /Ascendos/i
          'Ascendos'
        when /^XenServer/i
          'XenServer'
        when /XCP/i
          'XCP'
        when /^VirtuozzoLinux/i
          'VirtuozzoLinux'
        else
          'RedHat'
        end
      elsif Facter::Util::FileRead.exists?('/etc/SuSE-release')
        operatingsystem = case Facter::Util::FileRead.read('/etc/SuSE-release')
        when /^SUSE LINUX Enterprise Server/i
          'SLES'
        when /^SUSE LINUX Enterprise Desktop/i
          'SLED'
        when /^openSUSE/
          'OpenSuSE'
        else
          'SuSE'
        end
      elsif Facter::Util::FileRead.exists?('/etc/system-release')
        operatingsystem = 'Amazon'
      end
    end

    operatingsystem = 'unknown' if operatingsystem.nil?

    {'name' => operatingsystem}
  end

  chunk(:family, require: [:name]) do |os_name|
    family = case os_name['name']
    when "RedHat", "Fedora", "CentOS", "Scientific", "SLC", "Ascendos",
         "CloudLinux", "PSBM", "OracleLinux", "OVS", "OEL", "Amazon",
         "XenServer", "VirtuozzoLinux"
      "RedHat"
    when "LinuxMint", "Ubuntu", "Debian"
      "Debian"
    when "SLES", "SLED", "OpenSuSE", "SuSE"
      "Suse"
    when "Gentoo"
      "Gentoo"
    when "Archlinux", "Manjarolinux"
      "Archlinux"
    when "Mageia", "Mandriva", "Mandrake"
      "Mandrake"
    else
      Facter.value("kernel")
    end

    {'family' => family}
  end

  chunk(:architecture, require: [:name]) do |os_name|
    model = Facter::Core::Execution.execute('uname -m')

    arch = case model
    when "x86_64"
      case os_name['name']
      when "Debian", "Gentoo", "GNU/kFreeBSD", "Ubuntu"
        "amd64"
      else
        model
      end
    when /(i[3456]86|pentium)/
      case os_name['name']
      when "Gentoo"
        "x86"
      else
        "i386"
      end
    else
      model
    end

    {
      'architecture' => arch,
      'hardware' => model
    }
  end

  chunk(:release, require: [:name]) do |os_name|
    full = nil
    major = nil
    minor = nil

    case os_name['name']
    when "Alpine"
      if release = Facter::Util::FileRead.read('/etc/alpine-release')
        full = release.sub(/\s*$/, '')
      end
    when "Amazon"
      if (lsb_release = Facter::Core::Execution.exec('lsb_release -r')) && (! lsb_release.empty?)
        full = release.split(':').last.strip
      else
        if release = Facter::Util::FileRead.read('/etc/system-release')
          if match = /\d+\.\d+/.match(release)
            full = match[0]
          end
        end
      end
    when "AristaEOS"
      if release = Facter::Util::FileRead.read('/etc/Eos-release')
        if match = /\d+\.\d+(:?\.\d+)?[A-M]?$/.match(release)
          full = match[0]
        end
      end
    when "BlueWhite64"
      full = if release = Facter::Util::Read.read('/etc/bluewhite64-version')
        if match = /^\s*\w+\s+(\d+)\.(\d+)/.match(release)
          match[1] + "." + match[2]
        else
          "unknown"
        end
      end
    when "CentOS", "RedHat", "Scientific", "SLC", "Ascendos", "CloudLinux", "PSBM",
         "XenServer", "Fedora", "MeeGo", "OracleLinux", "OEL", "oel", "OVS", "ovs",
         "VirtuozzoLinux"
      case os_name['name']
      when "CentOS", "RedHat", "Scientific", "SLC", "Ascendos", "CloudLinux",
           "PSBM", "XenServer", "VirtuozzoLinux"
        releasefile = "/etc/redhat-release"
      when "Fedora"
        releasefile = "/etc/fedora-release"
      when "MeeGo"
        releasefile = "/etc/meego-release"
      when "OracleLinux"
        releasefile = "/etc/oracle-release"
      when "OEL", "oel"
        releasefile = "/etc/enterprise-release"
      when "OVS", "ovs"
        releasefile = "/etc/ovs-release"
      end

      full = if (release = Facter::Util::FileRead.read(releasefile))
        line = release.split("\n").first.chomp
        if match = /\(Rawhide\)$/.match(line)
          "Rawhide"
        elsif match = /release (\d[\d.]*)/.match(line)
          match[1]
        end
      end
    when "Debian"
      full = if (release = Facter::Util::FileRead.read('/etc/debian_version'))
        release.sub!(/\s*$/, '')
        release
      end
    when "LinuxMint"
      full = if (release = Facter::Util::FileRead.read('/etc/linuxmint/info'))
        if match = release.match(/RELEASE=(\d+)/)
          match[1]
        end
      end
    when "Mageia"
      full = if (release = Facter::Util::FileRead.read('/etc/mageia-release'))
        if match = release.match(/Mageia release ([0-9.]+)/)
          match[1]
        end
      end
    when "OpenWrt"
      full = if (release = Facter::Util::FileRead.read('/etc/openwrt_version'))
        if match = release.match(/^(\d+\.\d+.*)/)
          match[1]
        end
      end
    when "Slackware"
      full = if (release = Facter::Util::FileRead.read('/etc/slackware-version'))
        if match = release.match(/Slackware ([0-9.]+)/)
          match[1]
        end
      end
    when "Slamd64"
      full = if (release = Facter::Util::FileRead.read('/etc/slamd64-version'))
        if match = release.match(/^\s*\w+\s+(\d+)\.(\d+)/)
          match[1]
        end
      end
   when "SLES", "SLED", "OpenSuSE"
      full = if (release = Facter::Util::FileRead.read('/etc/SuSE-release'))
        if match = /^VERSION\s*=\s*(\d+)/.match(release)
          releasemajor = match[1]
          if match = /^PATCHLEVEL\s*=\s*(\d+)/.match(release)
            releaseminor = match[1]
          elsif match = /^VERSION\s=.*.(\d+)/.match(release)
            releaseminor = match[1]
          else
            releaseminor = "0"
          end
          releasemajor + "." + releaseminor
        else
          "unknown"
        end
      end
    when "Ubuntu"
      full = if (release = Facter::Util::FileRead.read('/etc/lsb-release'))
        if match = release.match(/DISTRIB_RELEASE=((\d+.\d+)(\.(\d+))?)/)
          # Return only the major and minor version numbers.  This behavior must
          # be preserved for compatibility reasons.
          match[2]
        end
      end
    when "VMwareESX"
      release = Facter::Core::Execution.exec('vmware -v')
      full = if (match = /VMware ESX .*?(\d.*)/.match(release))
        match[1]
      end
    else
      Facter.value(:kernelrelease)
    end

    case os_name['name']
    when 'Ubuntu'
      major = if (releasemajor = full.split("."))
        if releasemajor.length >= 2
          "#{releasemajor[0]}.#{releasemajor[1]}"
        else
          releasemajor[0]
        end
      end

      minor = if (releaseminor = full.split(".")[2])
        releaseminor
      end
    else
      major = if (releasemajor = full.split(".")[0])
        releasemajor
      end

      minor = if (releaseminor = full.split(".")[1])
        if releaseminor.include? "-"
          releaseminor.split("-")[0]
        else
          releaseminor
        end
      end
    end

    release_info = {
      'full'  => full,
      'major' => major,
      'minor' => minor
    }

    {'release' => release_info.reject{|_, v| v.nil?}}
  end
end

Facter.add(:os, :type => :aggregate) do
  confine :kernel => 'windows'

  chunk(:name) do
    {'name' => 'windows'}
  end

  chunk(:family) do
    {'family' => 'windows'}
  end

  chunk(:architecture) do
    # NOTE: Restricting the WMI query using -Property really makes a
    # performance difference for Win32_Processor
    processor_info = Facter::Core::Execution.execute(<<-PS1)
(Get-WmiObject -Class Win32_Processor -Property Architecture,Level,AddressWidth |
  Select-Object -First 1 -Property Architecture,Level,AddressWidth |
  Format-List|Out-String).Trim()
PS1

    arch, level, width = processor_info.lines.map do |l|
      # TODO: Log a message at debug level when one of these returns
      # a non-integer value.
      Integer(l.split(':').last.strip) rescue nil
    end
    level = (level > 5) ? 6 : level

    model = case arch
    when 11
      'neutral'        # PROCESSOR_ARCHITECTURE_NEUTRAL
    when 10
      'i686'           # PROCESSOR_ARCHITECTURE_IA32_ON_WIN64
    when 9
      # PROCESSOR_ARCHITECTURE_AMD64
      width == 32 ? "i#{level}86" : 'x86_64' # 32 bit OS on 64 bit CPU
    when 8
      'msil'            # PROCESSOR_ARCHITECTURE_MSIL
    when 7
      'alpha64'         # PROCESSOR_ARCHITECTURE_ALPHA64
    when 6
      'ia64'            # PROCESSOR_ARCHITECTURE_IA64
    when 5
      'arm'             # PROCESSOR_ARCHITECTURE_ARM
    when 4
      'shx'             # PROCESSOR_ARCHITECTURE_SHX
    when 3
      'powerpc'         # PROCESSOR_ARCHITECTURE_PPC
    when 2
      'alpha'           # PROCESSOR_ARCHITECTURE_ALPHA
    when 1
      'mips'            # PROCESSOR_ARCHITECTURE_MIPS
    when 0
      "i#{level}86" # PROCESSOR_ARCHITECTURE_INTEL
    else
      'unknown'            # PROCESSOR_ARCHITECTURE_UNKNOWN
    end

    architecture = case model
    when /(i[3456]86|pentium)/
      'x86'
    when 'x86_64'
      'x64'
    else
      model
    end

    {
      'architecture' => architecture,
      'hardware' => model
    }
  end

  chunk(:release) do
    version_info = Facter::Core::Execution.execute(<<-PS1)
(Get-WmiObject -Class Win32_OperatingSystem -Property BuildNumber,ProductType,ServicePackMajorVersion |
  Select-Object -First 1 -Property BuildNumber,ProductType,ServicePackMajorVersion |
  Format-List|Out-String).Trim()
PS1

    build, type, pack = version_info.lines.map do |l|
      # TODO: Log a message at debug level when one of these returns
      # a non-integer value.
      Integer(l.split(':').last.strip) rescue nil
    end

    release = case Facter.value(:kernelmajversion)
    when '10.0'
      type == 1 ? '10' : '2016'
    when '6.3'
      type == 1 ? "8.1" : "2012 R2"
    when '6.2'
      type == 1 ? "8" : "2012"
    when '6.1'
      type == 1 ? "7" : "2008 R2"
    when '6.0'
      type == 1 ? "Vista" : "2008"
    when '5.2'
      if type == 1
        "XP"
      elsif pack == 2
        "2003 R2"
      else
        "2003"
      end
    else
      Facter.value(:kernelrelease)
    end

    {
      'release' => {
        'full' => release,
        'major' => release
      }
    }
  end
end

Facter.add(:os, :type => :aggregate) do
  confine :kernel => 'aix'

  chunk(:name) do
    {'name' => 'AIX'}
  end

  chunk(:family) do
    {'family' => 'AIX'}
  end

  chunk(:architecture) do
    model_info = Facter::Core::Execution.exec('lsattr -El sys0 -a modelname')
    model = if (match = model_info.match(/modelname\s(\S+)\s/))
      match.captures.first
    else
      nil
    end

    arch_info = Facter::Core::Execution.exec('lsattr -El proc0 -a type')
    arch = if (match = arch_info.match(/type\s(\S+)\s/))
      match.captures.first
    else
      nil
    end

    architecture = {
      'architecture' => arch,
      'hardware' => model
    }

    architecture.reject{|_, v| v.nil?}
  end

  chunk(:release) do
    release_info = {
      'full'  => Facter.value(:kernelrelease),
      'major' => Facter.value(:kernelrelease).split('-')[0]
    }

    {'release' => release_info}
  end
end

Facter.add(:os, :type => :aggregate) do
  confine :kernel => 'sunos'

  chunk(:name) do
    output = Facter::Core::Execution.exec('uname -v')

    name = if output =~ /^joyent_/
      "SmartOS"
    elsif output =~ /^oi_/
      "OpenIndiana"
    elsif output =~ /^omnios-/
      "OmniOS"
    elsif Facter::Util::FileRead.exists?("/etc/debian_version")
      "Nexenta"
    else
      "Solaris"
    end

    {'name' => name}
  end

  chunk(:family) do
    {'family' => 'Solaris'}
  end

  chunk(:architecture) do
    arch = Facter::Core::Execution.execute('uname -m')

    {
      'architecture' => arch,
      'hardware' => arch
    }
  end

  chunk(:release, require: [:name]) do |osname|
    full = if (release = Facter::Util::FileFread.read('/etc/release'))
      line = release.split("\n").first

      # Solaris 10: Solaris 10 10/09 s10x_u8wos_08a X86
      # Solaris 11 (old naming scheme): Oracle Solaris 11 11/11 X86
      # Solaris 11 (new naming scheme): Oracle Solaris 11.1 SPARC
      if match = /\s+s(\d+)[sx]?(_u\d+)?.*(?:SPARC|X86)/.match(line)
        match.captures.join('')
      elsif match = /Solaris ([0-9\.]+(?:\s*[0-9\.\/]+))\s*(?:SPARC|X86)/.match(line)
        match.captures[0]
      else
        Facter.value(:kernelrelease)
      end
    else
      Facter(:kernelrelease).value
    end

    major = if osname['name'] == "Solaris"
      if match = full.match(/^(\d+)/)
        match.captures[0]
      end
    end

    minor = if osname['name'] == "Solaris"
      if match = full.match(/^\d+(?:\.|_u)(\d+)/)
        match.captures[0]
      end
    end

    release_info = {
      'full'  => full,
      'major' => major,
      'minor' => minor
    }

    {'release' => release_info.reject{|_, v| v.nil?}}
  end
end
