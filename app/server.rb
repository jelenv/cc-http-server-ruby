# frozen_string_literal: true

require 'socket'

server = TCPServer.new 4221
print "server started at: http://localhost:4221\n"

loop do
  client = server.accept
  request = client.gets
  print "<- | #{request}"
  method, path = request.split(' ')

  http_version = 'HTTP/1.1'
  status_code = '404 Not Found'
  if method == 'GET' && path == '/'
    status_code = '200 OK'
  elsif method == 'GET' && path.start_with?('/echo/')
    status_code = '200 OK'
    response_body = path.split('/').last.strip
    content_type = 'Content-Type: text/plain'
    content_len = "Content-Length: #{response_body.length}"
  end

  response = "#{http_version} #{status_code}\r\n"
  response += "#{content_type}\r\n" if content_type
  response += "#{content_len}\r\n" if content_len
  response += "\r\n"
  response += response_body if response_body

  client.puts response
  print "-> | #{response}\n"
  client.close
end
