require 'socket'
require 'packet.rb'
require 'lib'

class Receiver

  def initialize(file_name)
    @write_file_name = file_name
    @packets_received = []
    @max_seen_seq_num = 0

    prepare_sockets
    prepare_files
  end

  def prepare_sockets
    @socket = UDPSocket.new
    @socket.bind(Socket.gethostname, 0)
  end

  def prepare_files
    File.new(@write_file_name, "w")

    File.open(RECV_INFO, "w") do |f|
      f.write("#{Socket.gethostname} #{@socket.addr[1]}")
    end
  end

  def receive_dat_packet
    data, sender = @socket.recvfrom(512)
    @resp_port ||= sender[1]
    @resp_host ||= sender[2]

    Packet.build(data)
  end

  def reply_packet(type, seq_num=0)
    packet = Packet.new(type, seq_num)
    @socket.send(packet.to_s, 0, @resp_host, @resp_port)
    Helpers::print_log(SEND, packet)
  end

  def write_packets_to_file
    File.open(@write_file_name, "w") do |f|
      @packets_received.each { |p| f.write(p.data) }
    end
  end

  def validate_missing_data
    # determine if there is outstanding packets

    # file being transfered is empty
    return if @packets_received.empty? && @max_seen_seq_num == 0

    # check if all received packets are in sequence
    if @packets_received.last.seq_num != @max_seen_seq_num
      Helpers::terminate_with_error(MISSING_DATA, __FILE__, __LINE__)
    end

    # check if there received DAT packets are in sequence order
    @packets_received.each_with_index do |p, i|
      unless p.seq_num == i % MODULO
        Helpers::terminate_with_error(MISSING_DATA, __FILE__, __LINE__)
      end
    end
  end

  def run
    while true
      puts "BLOCKING waiting for DAT"

      packet = receive_dat_packet
      Helpers::print_log(RECV, packet)
      terminate_with_error(SEQ_NUM_OUT_OF_RANGE, __FILE__, __LINE__) if packet.seq_num < 0 || packet.seq_num >= MODULO

      break if packet.is_EOT?
      @max_seen_seq_num = Helpers::max_with_modulo([packet.seq_num, @max_seen_seq_num])

      process_received_packet(packet)
    end

    validate_missing_data
    reply_packet(EOT)
    write_packets_to_file
  end

end