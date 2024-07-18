# frozen_string_literal: true

# Response being sent from the server to the client
class HttpResponse
  require 'zlib'

  STATUS_MAP = {
    200 => 'OK',
    201 => 'Created',
    404 => 'Not Found'
  }.freeze

  attr_accessor :status
  attr_reader :headers

  def initialize(status = 404, headers = {})
    @status = status
    @headers = headers
  end

  def set_body(body, content_type, accept_encoding = nil)
    return if body.nil?

    @headers['Content-Type'] = content_type
    @headers['Content-Encoding'] = 'gzip' if accept_encoding&.include?('gzip')

    @body = @headers['Content-Encoding'] == 'gzip' ? Zlib.gzip(body) : body
    @headers['Content-Length'] = @body.length
  end

  def response_string
    response = "HTTP/1.1 #{@status} #{STATUS_MAP[@status]}\r\n"
    @headers.each do |key, value|
      response << "#{key}: #{value}\r\n"
    end
    response << "\r\n"
    response << @body if @body
    response
  end
end
