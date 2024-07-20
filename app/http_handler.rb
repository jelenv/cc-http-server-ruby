# frozen_string_literal: true

# Handles client connection and it's requests until disconnect
class HttpHandler
  require_relative 'http_response'
  require 'timeout'

  KEEP_ALIVE_TIMEOUT = 5 # seconds

  def initialize(client, files_dir)
    @client = client
    @files_dir = files_dir
  end

  def process
    loop do
      Timeout.timeout(KEEP_ALIVE_TIMEOUT) do
        request = parse_request
        break if request.empty?

        response, keep_alive = handle_request(request)
        send_response(response)

        return unless keep_alive
      end
    rescue EOFError, Errno::ECONNRESET, Timeout::Error
      break
    end
  ensure
    @client.close
  end

  private

  def handle_request(request)
    response = HttpResponse.new

    if request[:version] != 'HTTP/1.1'
      handle_unsupported_http_version(response)
      return [response, false]
    end

    case request[:method]
    when 'GET'
      handle_get_request(request[:path], request[:headers], response)
    when 'POST'
      handle_post_request(request[:path], request[:headers], request[:body], response)
    else
      response.status = 405
      response.headers['Allow'] = 'GET, POST'
    end

    keep_alive = keep_alive?(request[:headers], response)
    [response, keep_alive]
  end

  def handle_unsupported_http_version(response)
    response.status = 505
    response.set_body('HTTP Version Not Supported. This server only supports HTTP/1.1.', 'text/plain')
  end

  def handle_get_request(path, headers, response)
    case path
    when '/'
      response.status = 200
    when ->(path) { path.start_with? '/echo/' }
      response.status = 200
      response.set_body(path.split('/').last.strip, 'text/plain', headers['accept-encoding'])
    when '/user-agent'
      response.status = 200
      response.set_body(headers['user-agent'], 'text/plain', headers['accept-encoding'])
    when ->(path) { path.start_with? '/files/' }
      filename = path.split('/').last.strip
      if File.exist?("#{@files_dir}/#{filename}")
        response.status = 200
        file_content = File.read("#{@files_dir}/#{filename}", mode: 'rb')
        response.set_body(file_content, 'application/octet-stream')
      end
    end
  end

  def handle_post_request(path, headers, body, response)
    case path
    when ->(path) { path.start_with? '/files/' }
      filename = path.split('/').last.strip
      print "filename: #{filename}\n"
      if Dir.exist?(@files_dir.to_s) && headers['content-type'] == 'application/octet-stream'
        response.status = 201
        File.write("#{@files_dir}/#{filename}", body, mode: 'wb')
      end
    end
  end

  def keep_alive?(headers, response)
    keep_alive = false
    response.headers['Connection'] = 'close'
    is_success_response = [200, 201].include?(response.status)
    keep_alive_requested = headers['connection']&.downcase == 'keep-alive'
    if is_success_response && keep_alive_requested
      response.headers['Connection'] = 'keep-alive'
      response.headers['Keep-Alive'] = "timeout=#{KEEP_ALIVE_TIMEOUT}"
      keep_alive = true
    end
    keep_alive
  end

  def send_response(response)
    response_str = response.response_string
    @client.write response_str
    @client.flush
    print "-> | #{response_str}\n"
  end

  def parse_request
    request_line = @client.gets
    return {} unless request_line

    print "<- | #{request_line}"
    method, path, version = request_line.split
    headers = parse_headers
    body = @client.read(headers['content-length'].to_i) if headers['content-length']&.to_i&.positive?

    { version: version, method: method, path: path, headers: headers, body: body }
  end

  def parse_headers
    @client.gets("\r\n\r\n").split("\r\n").each_with_object({}) do |header, hash|
      key, value = header.split(':', 2)
      hash[key.downcase] = value.strip if key
    end
  end
end
