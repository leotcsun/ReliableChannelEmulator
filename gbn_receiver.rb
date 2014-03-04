require 'receiver'

class GBNReceiver < Receiver
  def initialize(file_name)
    super
    @expected_seq_num = 0
  end

  def process_received_packet(packet)
    if packet.seq_num == @expected_seq_num
      # accept the packet only if the sequence number is in order
      @packets_received << packet
      @expected_seq_num = (@expected_seq_num + 1) % MODULO
    end

    # reply with the previous in-order sequence number
    reply_packet(ACK, (@expected_seq_num - 1) % MODULO)
  end
end



###############################################################################
Helpers::terminate_with_error(SENDER_ARG_ERROR, __FILE__, __LINE__) unless ARGV.size == 1

gbn_receiver = GBNReceiver.new(ARGV[0])
gbn_receiver.run






