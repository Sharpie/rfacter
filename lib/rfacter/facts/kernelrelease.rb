# Fact: kernelrelease
#
# Purpose: Return the operating system's release number.
#
# Resolution:
#   On AIX, returns the output from the `oslevel -s` system command.
#   On Windows-based systems, uses `Get-WmiObject` to query Windows Management
#   for the `Win32_OperatingSystem` value.
#   Otherwise uses the output of `uname -r` system command.
#
# Caveats:
#
Facter.add(:kernelrelease) do
  setcode 'uname -r'
end

Facter.add(:kernelrelease) do
  confine :kernel => "aix"
  setcode 'oslevel -s'
end

Facter.add("kernelrelease") do
  confine :kernel => :openbsd
  setcode do
    version = Facter::Core::Execution.execute('sysctl -n kern.version')
    version.split(' ')[1]
  end
end

Facter.add(:kernelrelease) do
  confine :kernel => "hp-ux"
  setcode do
    version = Facter::Core::Execution.execute('uname -r')
    version[2..-1]
  end
end

Facter.add(:kernelrelease) do
  confine :kernel => "windows"
  setcode '(Get-WmiObject -Class Win32_OperatingSystem -Property Version).Version'
end
