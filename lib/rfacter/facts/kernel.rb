# Fact: kernel
#
# Purpose: Returns the operating system's name.
#
# Resolution:
#   Uses Ruby's RbConfig to find host_os, if that is a Windows derivative, then
#   returns `windows`, otherwise returns the output of `uname -s` verbatim.
#
# Caveats:
#

Facter.add(:kernel) do
  setcode do
    # FIXME: This is a bit naive as winrm could conceivably connect to
    # PowerShell running on POSIX and ssh could connect to a Windows node due
    # to recent investments by Microsoft in Open Source.
    #
    # This also won't work correctly for local execution on a Windows node.
    case NODE.value.scheme
    when 'winrm'
      'windows'
    else
      Facter::Core::Execution.exec("uname -s")
    end
  end
end
