require 'cgi'
require 'json'
require 'time'

class RequestHandler
  def initialize(scanner)
    @scanner = scanner
  end

  def handle(req, res)
    query_params = {}
    if req.query_string
      CGI.parse(req.query_string).each { |k, v| query_params[k] = v.first }
    end

    case query_params['action']
    when 'scan'
      handle_scan_request(query_params, res)
    else
      handle_html_request(query_params, res)
    end
  end

  private

  def handle_scan_request(query_params, res)
    hosts = @scanner.network_utils.parse_hosts_from_query(query_params)
    ports = @scanner.network_utils.parse_ports_from_query(query_params)
    timeout = query_params['timeout']&.to_f || ServiceScanner::DEFAULT_TIMEOUT
    timeout = [timeout, 0.05].max

    puts "Scanning #{hosts.size} hosts × #{ports.size} ports with #{ServiceScanner::MAX_THREADS} threads..."
    start_time = Time.now
    
    results = @scanner.port_scanner.scan_parallel(hosts, ports, timeout, @scanner.http_client)
    
    end_time = Time.now
    open_ports = results.size  # OPENポートのみなのでresults.sizeがopen_ports
    services = results.count { |r| !r[:error] }
    
    puts "Scan completed in #{(end_time - start_time).round(2)} seconds."
    puts "Found #{open_ports} open ports, #{services} HTTP/HTTPS services."

    res.status = 200
    res.content_type = 'application/json; charset=utf-8'
    res.body = JSON.generate({
      ok: true,
      results: results,
      scan_time: (end_time - start_time).round(2),
      total_checks: hosts.size * ports.size,
      found_services: services,
      open_ports: open_ports
    })
  end

  def handle_html_request(query_params, res)
    res.status = 200
    res.content_type = 'text/html; charset=utf-8'
    res.body = @scanner.html_generator.generate_html(query_params, @scanner.network_utils)
  end
end
