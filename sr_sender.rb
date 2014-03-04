require 'sender.rb'

class SRSender < Sender

  def process_ack_packet(ack_packet)
    # mark packet as sent if the ACK sequence number is in the window
    if Helpers::number_in_window(ack_packet.seq_num, @window_index, @window_index + N)
      mark_packet_as_sent(ack_packet.seq_num)
    end
  end

  def send_dat_packets
    @window.each do |p|
      next if p.sent?

      p.expire_time = Time.now + @timeout
      @socket.send(p.to_s, 0, @host, @port)
      Helpers::print_log(SEND, p)
    end
  end

end

###############################################################################
Helpers::terminate_with_error(SENDER_ARG_ERROR, __FILE__, __LINE__) unless ARGV.size == 2

sr_sender = SRSender.new(ARGV[0], ARGV[1])
sr_sender.run