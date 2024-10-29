require "socket"
require "optparse"

udp_data_count = 40
tcp_data_count = 50
output_duration_sec = 4.0

opt = OptionParser.new
opt.on("--udp-data-count num") { |v| udp_data_count = v.to_i }
opt.on("--tcp-data-count num") { |v| tcp_data_count = v.to_i }
opt.on("--duration num") { |v| output_duration_sec = v.to_f }
opt.parse!(ARGV)


threads = []
threads << Thread.new do
  i = 0
  begin
    s = UDPSocket.open
    s.connect("localhost", 5170)

    loop do
      s.puts "[udp][#{i}] hello"
      i += 1
      sleep (output_duration_sec / udp_data_count)
      break if i == udp_data_count
    end
  rescue Errno::ECONNRESET, Errno::ECONNREFUSED
    retry
  end
ensure
  s.close
end

threads << Thread.new do
  i = 0
  begin
    s = TCPSocket.open("localhost", 5170)

    loop do
      s.puts "[tcp][#{i}] hello"
      i += 1
      sleep (output_duration_sec / tcp_data_count)
      break if i == tcp_data_count
    end
  rescue Errno::ECONNRESET, Errno::ECONNREFUSED
    retry
  end
ensure
  s.close
end

threads.each(&:join)
