#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require_relative 'lib/network_utils'
require_relative 'lib/port_scanner'
require_relative 'lib/http_client'
require_relative 'lib/html_generator'
require_relative 'lib/request_handler'

class ServiceScanner
  DEFAULT_HTTP_PORTS = [80, 81, 88] + (8000..8008).to_a + (8080..8088).to_a + (8800..8888).to_a + [8181, 8500] + (9000..9099).to_a
  DEFAULT_HTTPS_PORTS = [443, 8443] + (444...499).to_a
  DEFAULT_TIMEOUT = 0.25
  MAX_THREADS = 50

  def initialize
    @network_utils = NetworkUtils.new
    @port_scanner = PortScanner.new
    @http_client = HttpClient.new
    @html_generator = HtmlGenerator.new
    @request_handler = RequestHandler.new(self)
  end

  attr_reader :network_utils, :port_scanner, :http_client, :html_generator, :request_handler

  def handle_request(req, res)
    @request_handler.handle(req, res)
  end
end

# サーバー起動
if __FILE__ == $0
  require 'optparse'
  require 'webrick'

  port = 4567
  host = '0.0.0.0'

  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"
    opts.on('-p', '--port PORT', Integer, 'Port number (default: 4567)') { |v| port = v }
    opts.on('-h', '--host HOST', 'Host to bind (default: 0.0.0.0)') { |v| host = v }
    opts.on('--help', 'Show this help') { puts opts; exit }
  end.parse!

  scanner = ServiceScanner.new
  
  server = WEBrick::HTTPServer.new(
    Port: port,
    BindAddress: host,
    Logger: WEBrick::Log.new($stderr, WEBrick::Log::INFO),
    AccessLog: [[
      $stderr, 
      WEBrick::AccessLog::COMBINED_LOG_FORMAT
    ]]
  )

  server.mount_proc('/') do |req, res|
    scanner.handle_request(req, res)
  end

  trap('INT') { server.shutdown }
  
  puts "Starting Ruby Service Scanner on http://#{host}:#{port}/"
  puts "Press Ctrl+C to stop"
  puts "Max parallel threads: #{ServiceScanner::MAX_THREADS}"
  
  server.start
end
