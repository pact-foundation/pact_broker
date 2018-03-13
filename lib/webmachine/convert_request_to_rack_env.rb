module Webmachine
  class ConvertRequestToRackEnv
    def self.call(request)
      env = {
        'REQUEST_METHOD' => request.method.upcase,
        'CONTENT_TYPE' => request.headers['Content-Type'],
        'PATH_INFO' => request.uri.path,
        'QUERY_STRING' => request.uri.query || "",
        'SERVER_NAME' => request.uri.host,
        'SERVER_PORT' => request.uri.port.to_s,
        'SCRIPT_NAME' => '',
        'rack.url_scheme' => request.uri.scheme,
        'rack.input' => request.body.to_io ? StringIO.new(request.body.to_s) : nil
      }
      http_headers = request.headers.each do | key, value |
        env[convert_http_header_name_to_rack_header_name(key)] = value
      end
      env
    end

    def self.convert_http_header_name_to_rack_header_name(http_header_name)
      if http_header_name.downcase == 'content-type' || http_header_name.downcase ==  'content-length'
        http_header_name.upcase.gsub('-', '_')
      else
        "HTTP_" + http_header_name.upcase.gsub('-', '_')
      end
    end
  end
end
