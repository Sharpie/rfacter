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
