# frozen_string_literal: true

require 'socket'
require_relative 'http_handler'

server = TCPServer.new 4221
print "server started at: http://localhost:4221\n"

loop do
  Thread.start(server.accept) do |client|
    handler = HttpHandler.new(client)
    handler.process
  end
end
