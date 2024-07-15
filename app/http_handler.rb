# frozen_string_literal: true

# Handles client connection and it's requests until disconnect
class HttpHandler
  require_relative 'http_response'

  def initialize(client, files_dir)
    @client = client
    @files_dir = files_dir
  end

  def process
    loop do
      request_line = @client.gets
      break unless request_line

      print "<- | #{request_line}"
      method, path, = request_line.split
      headers = parse_headers

      response = HttpResponse.new

      if method == 'GET'
        case path
        when '/'
          response.status = 200
        when ->(path) { path.start_with? '/echo/' }
          response.status = 200
          response.set_body(path.split('/').last.strip, 'text/plain')
        when '/user-agent'
          response.status = 200
          response.set_body(headers['user-agent'], 'text/plain')
        when ->(path) { path.start_with? '/files/' }
          filename = path.split('/').last.strip
          if File.exist?("#{@files_dir}/#{filename}")
            response.status = 200
            file_content = File.read("#{@files_dir}/#{filename}", mode: 'rb')
            response.set_body(file_content, 'application/octet-stream')
          else
            response.status = 404
          end
        else
          response.status = 404
        end
      end

      if response.status == 200
        if headers['connection']&.downcase == 'keep-alive'
          response.headers['Connection'] = 'keep-alive'
          keep_alive = true
        else
          response.headers['Connection'] = 'close'
          keep_alive = false
        end
      end

      response_str = response.response_string
      @client.write response_str
      print "-> | #{response_str}\n"

      break unless keep_alive
    end
  rescue EOFError, Errno::ECONNRESET
    # client closed the connection
  ensure
    @client.close
  end

  private

  def parse_headers
    headers = @client.gets "\r\n\r\n"
    headers = headers.split("\r\n")
    headers_parsed = {}
    headers.each do |header|
      key, value = header.split(':')
      headers_parsed[key.downcase] = value.strip
    end
    headers_parsed
  end
end
