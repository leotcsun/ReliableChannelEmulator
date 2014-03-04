require 'sender.rb'

class GBNSender < Sender

  def process_ack_packet(ack_packet)
    mark_packet_as_sent(ack_packet.seq_num)
  end

  def mark_packet_as_sent(seq_num)
    super

    # mark all older packets as sent
    # since GBN receiver reply with the largest in-order sequence num
    # which implies that all packets with lower sequence num have been successfully received
    index = @packets_to_send.rindex { |p| p.sent? }
    (0..index).each { |i| @packets_to_send[i].mark_as_sent! } if index
  end
end


###############################################################################
Helpers::terminate_with_error(SENDER_ARG_ERROR, __FILE__, __LINE__) unless ARGV.size == 2

gbn_sender = GBNSender.new(ARGV[0], ARGV[1])
gbn_sender.run
