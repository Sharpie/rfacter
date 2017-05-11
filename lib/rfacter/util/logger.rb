require 'logger'

require 'rfacter'

# RFacter Logger class
#
# This class provides all the methods of a standard Ruby Logger plus the
# following methods used by the Facter API:
#
#   - `warnonce`
#   - `debugonce`
#   - `log_exception`
#
# @api private
# @since 0.1.0
class RFacter::Util::Logger < ::Logger
  @@warn_messages = Hash.new
  @@debug_messages = Hash.new

  def warnonce(msg)
    if @@warn_messages[msg].nil?
      self.warn(msg)
      @@warn_messages[msg] = true
    end
  end

  def debugonce(msg)
    if @@debug_messages[msg].nil?
      self.debug(msg)
      @@debug_messages[msg] = true
    end
  end

  def log_exception(exception, message = nil)
    message = exception.message if message.nil?

    output = []
    output << message
    output.concat(exception.backtrace)

    self.warn(output.flatten.join("\n"))
  end
end
