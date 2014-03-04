class Packet
  attr_accessor :type, :seq_num, :data, :expire_time

  def initialize(type, seq_num, data="")
    @type = type
    @seq_num = seq_num
    @data = data
    @expire_time = nil

    @sent = false
  end

  def self.build(string)
    packet_type = Packet.extract_field(string[0..3])
    packet_sequence_num = Packet.extract_field(string[4..7])
    packet_data = string[12..string.size]

    Packet.new(packet_type, packet_sequence_num, packet_data)
  end

  def self.extract_field(field)
    field.unpack("N")[0].to_i
  end

  def to_s
    "#{[type].pack('N')}#{[seq_num].pack('N')}#{[length].pack("N")}#{data}"
  end

  def length
    data.size + 12
  end

  def is_EOT?
    @type == EOT
  end

  def sent?
    @sent
  end

  def mark_as_sent!
    @sent = true
  end
end