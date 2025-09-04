require 'socket'
require 'ipaddr'
require 'cgi'

class NetworkUtils
  def get_local_ips
    ips = []
    
    # システムのIPアドレスを取得
    begin
      hostname = Socket.gethostname
      ips << Socket.getaddrinfo(hostname, nil).map { |addr| addr[3] }.uniq
    rescue
      # ignore
    end

    # 各種ネットワークインターフェースから取得
    begin
      Socket.ip_address_list.each do |addr|
        if addr.ipv4? && !addr.ipv4_loopback? && !addr.ipv4_multicast?
          ips << addr.ip_address
        end
      end
    rescue
      # ignore
    end

    # hostname -I での取得を試行
    begin
      result = `hostname -I 2>/dev/null`.strip
      if $?.success? && !result.empty?
        result.split.each { |ip| ips << ip if valid_ip?(ip) }
      end
    rescue
      # ignore
    end

    # デフォルト
    ips << '127.0.0.1'
    
    ips.flatten.uniq.select { |ip| valid_ip?(ip) }
  end

  def valid_ip?(ip)
    begin
      !!IPAddr.new(ip)
    rescue
      false
    end
  end

  def parse_hosts_from_query(query_params)
    if query_params['hosts'] && !query_params['hosts'].empty?
      hosts = query_params['hosts'].split(',').map(&:strip).reject(&:empty?)
      return hosts unless hosts.empty?
    end
    
    # デフォルト値
    ips = get_local_ips
    (['localhost', '127.0.0.1'] + ips).uniq
  end

  def parse_ports_from_query(query_params)
    ports = []

    if query_params['ports'] && !query_params['ports'].empty?
      query_params['ports'].split(',').each do |p|
        port = p.strip.to_i
        ports << port if port > 0
      end
    end

    if query_params['range'] && !query_params['range'].empty?
      if match = query_params['range'].match(/^(\d{1,5})-(\d{1,5})$/)
        start_port, end_port = match[1].to_i, match[2].to_i
        start_port, end_port = end_port, start_port if start_port > end_port
        start_port = [[start_port, 1].max, 65535].min
        end_port = [[end_port, 1].max, 65535].min
        ports.concat((start_port..end_port).to_a)
      end
    end

    # デフォルトポートを追加（ポートが指定されていない場合のみ）
    if ports.empty?
      ports = (ServiceScanner::DEFAULT_HTTP_PORTS + ServiceScanner::DEFAULT_HTTPS_PORTS).dup
    end

    ports.uniq.select { |p| p >= 1 && p <= 65535 }.sort
  end
end
