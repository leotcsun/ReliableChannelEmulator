require 'receiver.rb'

class SRReceiver < Receiver

  def initialize(*args)
    super
    @buffer =[]
    @recv_base = 0
  end

  def process_received_packet(packet)
    if Helpers::number_in_window(packet.seq_num, @recv_base, @recv_base + N + 1)
      # packet is in the accepting window
      reply_packet(ACK, packet.seq_num)

      if packet.seq_num == @recv_base
        # accept packet
        @packets_received << packet
        move_buffered_packets
      else
        # buffer packet
        @buffer << packet unless @buffer.map(&:seq_num).include?(packet.seq_num)
      end
    elsif Helpers::number_in_window(packet.seq_num, @recv_base - N, @recv_base - 1)
      # packet is in the previous accepting window, no action required
      reply_packet(ACK, packet.seq_num)
    end

    update_recv_base
  end

  def move_buffered_packets
    # move buffered packets into the received list of pacekts if they are in sequence
    return if @buffer.empty?

    expected_seq_num = (@recv_base + 1) % MODULO
    @buffer = @buffer.sort_by(&:seq_num)

    while !@buffer.empty?
      packet = @buffer[0]

      if packet.seq_num == expected_seq_num
        expected_seq_num += 1
        @packets_received << packet
        @buffer = @buffer.drop(1)
      else
        break
      end
    end
  end

  def update_recv_base
    return if @packets_received.empty?
    @recv_base = (@packets_received.last.seq_num + 1) % MODULO
  end

  def validate_missing_data
    move_buffered_packets
    super
  end
end

###############################################################################
Helpers::terminate_with_error(SENDER_ARG_ERROR, __FILE__, __LINE__) unless ARGV.size == 1

sr_receiver = SRReceiver.new(ARGV[0])
sr_receiver.run

