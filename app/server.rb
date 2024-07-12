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

  http_version = 'HTTP/1.1'
  status_code = '404 Not Found'
  if method == 'GET' && path == '/'
    status_code = '200 OK'
  elsif method == 'GET' && path.start_with?('/echo/')
    status_code = '200 OK'
    path_parts = path.split('/')
    response_body = path_parts[2]
    content_type = 'Content-Type: text/plain'
    content_len = "Content-Length: #{response_body.length}"
  end

  response = "#{http_version} #{status_code}\r\n"
  response += "#{content_type}\r\n" if content_type
  response += "#{content_len}\r\n" if content_len
  response += "\r\n"
  response += response_body if response_body

  client_socket.puts response
  print "-> | #{response}\n"
  client_socket.close
end
