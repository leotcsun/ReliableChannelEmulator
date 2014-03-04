require 'socket'
require 'packet.rb'
require 'lib.rb'
require 'timeout'

class Sender

  def initialize(timeout, file_name)
    @timeout = timeout.to_i / 1000.0
    @file_name = file_name

    prepare_sockets
    prepare_packets
  end

  def prepare_sockets
    @socket = UDPSocket.new

    File.open(CHANNEL_INFO, "r").each_line do |line|
      contents = line.split(" ")
      @host = contents[0]
      @port = contents[1]
    end
  end

  def prepare_packets
    @packets_to_send = []
    seq_num = 0

    File.open(@file_name) do |file|
      until file.eof?
        buffer = file.read(500)
        @packets_to_send << Packet.new(DAT, seq_num, buffer)
        seq_num = (seq_num + 1) % MODULO
      end
    end
  end

  def packets_left_to_send?
    @window_index < @packets_to_send.size
  end

  def process_eot_packets
    eot_packet_to_send = Packet.new(EOT, 0)
    @socket.send(eot_packet_to_send.to_s, 0, @host, @port)
    Helpers::print_log(SEND, eot_packet_to_send)

    # loop and discard any deplayed non-EOT packet
    while true
      puts "BLOCKING waiting for EOT"
      data, sender = @socket.recvfrom(512)
      packet = Packet.build(data)
      Helpers::print_log(RECV, packet)

      break if packet.is_EOT?
    end
  end

  def send_dat_packets
    @window.each do |p|
      p.expire_time = Time.now + @timeout
      @socket.send(p.to_s, 0, @host, @port)
      Helpers::print_log(SEND, p)
    end
  end

  def receive_ack_packets
    window_copy = @window

    while true
      # All packets in window have timed-out or ACKed
      break if window_copy.empty?

      # use the oldest in-flight packet to update timeout
      wait_time = window_copy.first.expire_time - Time.now
      break if wait_time < 0

      data, sender = nil
      begin
        Timeout.timeout(wait_time) do
          puts "BLOCKING waiting for ACK"
          data, sender = @socket.recvfrom(512)
        end
      rescue Timeout::Error
        window_copy.drop(1)
        break
      end

      if data && sender
        ack_packet = Packet.build(data)
        Helpers::print_log(RECV, ack_packet)
        Helpers::sendrate_with_error(UNEXPECTED_EOT_ERROR, __FILE__, __LINE__) if ack_packet.is_EOT?

        # remove ACKed packets from window
        window_copy = window_copy.delete_if { |p| p.seq_num == ack_packet.seq_num }
        process_ack_packet(ack_packet)
      end
   end

   update_window_index
  end

  def run
    @window_index = 0

    while packets_left_to_send?
      @window = @packets_to_send.slice(@window_index, N)

      send_dat_packets
      receive_ack_packets
    end

    process_eot_packets
  end

  def mark_packet_as_sent(seq_num)
    # mark a packet as sent only if the packet is in the window
    index = @packets_to_send.index { |p| !p.sent? && p.seq_num == seq_num }
    return unless index && index.between?(@window_index, @window_index + N)

    @packets_to_send[index].mark_as_sent!
  end

  def update_window_index
    # move window index to the first unsent packet
    @window_index = @packets_to_send.index { |p| !p.sent? }
    @window_index ||= @packets_to_send.size
  end
end

