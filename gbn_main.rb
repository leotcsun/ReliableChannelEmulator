require 'gbn_sender.rb'

timeout = ARGV[0]
file_name = ARGV[1]

gbn_sender = GBNSender.new(timeout, file_name)
gbn_sender = run