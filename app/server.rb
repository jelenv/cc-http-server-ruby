# frozen_string_literal: true

require 'optparse'
require 'socket'
require_relative 'http_handler'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: server.rb [options]'
  opts.on('-d=DIR', '--directory=DIR', 'Specify directory where to look for files') do |dir|
    options[:directory] = dir
  end
end.parse!

options[:directory] = Dir.pwd unless options[:directory]

server = TCPServer.new 4221
print "server started at: http://localhost:4221\n"
print "files directory set to: #{options[:directory]}\n"

loop do
  Thread.start(server.accept) do |client|
    handler = HttpHandler.new(client, options[:directory])
    handler.process
  end
end
