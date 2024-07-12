# frozen_string_literal: true

require 'socket'

server = TCPServer.new 4221
print "server started at: http://localhost:4221\n"

loop do
  client_socket = server.accept
  print "++ client connected\n"
  print "<- | #{client_socket.gets}"
  response = 'HTTP/1.1 200 OK'
  client_socket.puts "#{response}\r\n\r\n"
  print "-> | #{response}\n"
  client_socket.close
  print "-- client disconnected\n"
end

