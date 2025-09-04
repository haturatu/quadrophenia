require 'net/http'
require 'net/https'
require 'uri'
require 'openssl'
require 'cgi'

class HttpClient
  def try_http_request(host, port, timeout, https_preferred = false)
    # 最初に指定されたプロトコルでリクエスト
    initial_scheme = https_preferred ? 'https' : 'http'
    result = do_request(initial_scheme, host, port, timeout)
    
    # デバッグ情報を追加
    puts "DEBUG: Initial request - Scheme: #{initial_scheme}, Host: #{host}, Port: #{port}, Status: #{result[:status]}, Error: #{result[:error]}"
    
    # HTTP 400エラーまたはSSLエラーの場合、プロトコルを切り替えて再試行
    if (result[:error] && result[:error_message].include?('SSL')) || 
       (result[:status] == 400 && initial_scheme == 'http')
      
      alternate_scheme = initial_scheme == 'http' ? 'https' : 'http'
      puts "DEBUG: Trying alternate scheme: #{alternate_scheme}"
      
      alternate_result = do_request(alternate_scheme, host, port, timeout)
      
      # 代替プロトコルが成功した場合のみ返す
      unless alternate_result[:error]
        puts "DEBUG: Alternate scheme succeeded: #{alternate_scheme}"
        return alternate_result
      else
        puts "DEBUG: Alternate scheme also failed: #{alternate_scheme}, Error: #{alternate_result[:error_message]}"
      end
    end
    
    # 元の結果を返す（エラーでも400でもない場合、または代替プロトコルも失敗した場合）
    result
  end

  def do_request(scheme, host, port, timeout)
    begin
      uri = URI("#{scheme}://#{host}:#{port}/")
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = timeout
      http.read_timeout = timeout
      
      if scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      request = Net::HTTP::Head.new(uri.path.empty? ? '/' : uri.path)
      request['Host'] = host
      request['User-Agent'] = 'Ruby-Service-Scanner/1.0'
      request['Accept'] = 'text/html, */*'
      request['Connection'] = 'close'

      response = http.request(request)
      
      # GETリクエストでボディも取得してタイトル抽出
      title = ''
      begin
        get_request = Net::HTTP::Get.new(uri.path.empty? ? '/' : uri.path)
        get_request['Host'] = host
        get_request['User-Agent'] = 'Ruby-Service-Scanner/1.0'
        get_request['Accept'] = 'text/html, */*'
        get_request['Connection'] = 'close'
        
        get_response = http.request(get_request)
        if get_response.body && (get_response.content_type&.include?('text/html') || get_response.body.include?('<title>'))
          if match = get_response.body.match(/<title[^>]*>(.*?)<\/title>/mi)
            title = CGI.unescapeHTML(match[1]).strip
          end
        end
      rescue => e
        # タイトル取得失敗は無視
      end

      {
        error: false,
        scheme: scheme,
        host: host,
        port: port,
        status: response.code.to_i,
        headers: response.to_hash,
        server: response['Server'] || '',
        location: response['Location'] || '',
        title: title
      }
    rescue => e
      {
        error: true,
        error_message: e.message,
        scheme: scheme,
        host: host,
        port: port
      }
    end
  end
end
