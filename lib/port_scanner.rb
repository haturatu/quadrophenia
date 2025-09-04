require 'socket'
require 'thread'

class PortScanner
  def initialize
    @mutex = Mutex.new
  end

  def check_port_open(host, port, timeout)
    begin
      socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, [timeout, 0].pack("l_2"))
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, [timeout, 0].pack("l_2"))
      
      begin
        addr = Socket.sockaddr_in(port, host)
        socket.connect_nonblock(addr)
      rescue IO::WaitWritable
        if IO.select(nil, [socket], nil, timeout)
          begin
            socket.connect_nonblock(addr)
          rescue Errno::EISCONN
            # Connected
          end
        else
          raise Errno::ETIMEDOUT
        end
      end
      
      socket.close
      true
    rescue => e
      false
    ensure
      socket.close if socket && !socket.closed?
    end
  end

  def scan_parallel(hosts, ports, timeout, http_client)
    results = []
    threads = []
    work_queue = Queue.new
    
    # 作業をキューに追加
    hosts.each do |host|
      ports.each do |port|
        work_queue << [host, port]
      end
    end

    # ワーカースレッド作成
    thread_count = [ServiceScanner::MAX_THREADS, work_queue.size].min
    thread_count.times do
      threads << Thread.new do
        while !work_queue.empty?
          begin
            host, port = work_queue.pop(true)  # non_block = true
            
            # ポートが開いているかチェック
            port_open = check_port_open(host, port, timeout)
            
            next unless port_open  # OPENポートのみ処理
            
            # HTTPSポートかどうかをより厳密に判定
            https_preferred = ServiceScanner::DEFAULT_HTTPS_PORTS.include?(port) ||
              port == 443 ||
              port == 8443 ||
              port == 444 ||
              port == 9443 ||
              port == 10443

            result = http_client.try_http_request(host, port, timeout, true)

            
            result_data = {
              url: "#{result[:scheme]}://#{host}:#{port}/",
              host: host,
              port: port,
              scheme: result[:scheme],
              status: result[:error] ? nil : result[:status],
              server: result[:server] || '',
              title: result[:title] || '',
              location: result[:location] || '',
              port_open: true,  # OPENポートのみなので常にtrue
              error: result[:error],
              error_message: result[:error_message] || ''
            }
            
            @mutex.synchronize do
              results << result_data
            end
          rescue ThreadError
            # キューが空
            break
          end
        end
      end
    end

    # 全スレッドの完了を待機
    threads.each(&:join)
    
    # 結果をソート（ホスト、ポート順）
    results.sort! do |a, b|
      [a[:host], a[:port]] <=> [b[:host], b[:port]]
    end

    results
  end
end
