# frozen_string_literal: true

require 'socket'

server = TCPServer.new 4221
print "server started at: http://localhost:4221\n"

loop do
  client_socket = server.accept
  request = client_socket.gets
  print "<- | #{request}"
  request_parts = request.split(' ')
  method = request_parts[0]
  path = request_parts[1]

  response = ''
  if method == 'GET' && path == '/'
    response = 'HTTP/1.1 200 OK'
  else
    response = 'HTTP/1.1 404 Not Found'
  end

  client_socket.puts "#{response}\r\n\r\n"
  print "-> | #{response}\n"
  client_socket.close
end
