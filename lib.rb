DAT = 0x00
ACK = 0x01
EOT = 0x02

SEND = 0
RECV = 1

PACKET_TYPES = ["DAT", "ACK", "EOT"]
ACTION_TYPES = ["SEND", "RECV"]

N = 10
MODULO = 32

CHANNEL_INFO = "channelInfo"
RECV_INFO = "recvInfo"

RECEIVER_ARG_ERROR = <<-ERR
  WRONG NUMBER OF ARGUMENTS
  -> ./receiver <filename>
  program terminated
ERR

SENDER_ARG_ERROR = <<-ERR
  WRONG NUMBER OF ARGUMENTS
  -> ./sender <timeout> <filename>
  program termianted
ERR

UNEXPECTED_EOT_ERROR = "Unexpected EOT packet received, program terminated"
SEQ_NUM_OUT_OF_RANGE = "Sequence number out of range, program terminated"
MISSING_DATA = "EOT received with missing data, program terminated"

module Helpers

  def self.print_log(action, packet)
    puts "PKT #{ACTION_TYPES[action]} #{PACKET_TYPES[packet.type]} #{packet.seq_num} #{packet.length}"
  end

  def self.max_with_modulo(array)
    # return the largest(latest) sequence number within the given array
    # this method takes modulo into account to correctly handle special cases
    #  such as [30, 31, 0, 1, 2], 2 is identified as larger than 31
    return nil if array.empty?

    max = array.max
    min = array.min

    if max - min > 2 * N
      array.reject { |i| i > N }.max
    else
      array.max
    end
  end

  def self.number_in_window(num, low, high)
    # determine if num is within the window [low, high]
    # this method takes modulo into account to correctly handle special cases
    #   such as [28, 31, 2, 3], 0 is within the window but 10 isnt

    low %= MODULO
    high %= MODULO

    high += MODULO if low > high
    num >= low && num <= high
  end

  def self.terminate_with_error(error, file, line)
    puts "Error near line #{line} in file #{file}"
    puts error
    exit(1)
  end
end
