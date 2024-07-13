# frozen_string_literal: true

require 'socket'

def parse_headers(client)
  headers = client.gets "\r\n\r\n"
  headers = headers.split("\r\n")
  headers_parsed = {}
  headers.each do |header|
    key, value = header.split(':')
    headers_parsed[key.downcase] = value.strip
  end
  headers_parsed
end

def handle_client(client)
  loop do
    close_connection = handle_request(client)
    break if close_connection || client.closed? || client.eof?
  end
  client.close
end

def handle_request(client)
  request_line = client.gets
  return nil unless request_line

  print "<- | #{request_line}"
  method, path, = request_line.split
  headers = parse_headers(client)

  http_version = 'HTTP/1.1'
  status_code = '404 Not Found'
  content_type = nil
  content_len = nil
  response_body = nil

  status_code = '200 OK' if method == 'GET' && path == '/'

  if method == 'GET' && path.start_with?('/echo/')
    status_code = '200 OK'
    response_body = path.split('/').last.strip
    content_type = 'Content-Type: text/plain'
    content_len = "Content-Length: #{response_body.length}"
  end

  if method == 'GET' && path == '/user-agent'
    status_code = '200 OK'
    response_body = headers['user-agent']
    content_type = 'Content-Type: text/plain'
    content_len = "Content-Length: #{response_body.length}"
  end

  response = "#{http_version} #{status_code}\r\n"
  response += "#{content_type}\r\n" if content_type
  response += "#{content_len}\r\n" if content_len
  response += "\r\n"
  response += response_body if response_body

  client.write response
  print "-> | #{response}\n"

  # TODO: fix and improve the keep-alive implementation
  true
rescue EOFError, Errno::ECONNRESET
  true
end

server = TCPServer.new 4221
print "server started at: http://localhost:4221\n"

loop do
  Thread.start(server.accept) do |client|
    handle_client(client)
  end
end
