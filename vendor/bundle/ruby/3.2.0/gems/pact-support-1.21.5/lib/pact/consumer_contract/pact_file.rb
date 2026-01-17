require "net/http"
require "pact/configuration"
require "pact/http/authorization_header_redactor"

module Pact
  module PactFile
    extend self

    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 5
    RETRY_LIMIT = 3

    class HttpError < StandardError
      attr_reader :uri, :response

      def initialize(uri, response)
        @uri, @response = uri, response
        super("HTTP request failed: status=#{response.code}")
      end
    end

    def read uri, options = {}
      uri_string = uri.to_s
      pact = render_pact(uri_string, options)
      if options[:save_pactfile_to_tmp]
        save_pactfile_to_tmp pact, ::File.basename(uri_string)
      end
      pact
    rescue StandardError => e
      $stderr.puts "Error reading file from #{uri}"
      $stderr.puts "#{e.to_s} #{e.backtrace.join("\n")}"
      raise e
    end

    def save_pactfile_to_tmp pact, name
      ::FileUtils.mkdir_p Pact.configuration.tmp_dir
      ::File.open(Pact.configuration.tmp_dir + "/#{name}", "w") { |file|  file << pact}
    rescue Errno::EROFS
      # do nothing, probably on RunKit
    end

    def render_pact(uri_string, options)
      local?(uri_string) ? get_local(uri_string, options) : get_remote_with_retry(uri_string, options)
    end

    private

    def local? uri
      !uri.start_with?("http://", "https://")
    end

    def get_local(filepath, _)
      File.read windows_safe(filepath)
    end

    def get_remote_with_retry(uri_string, options)
      uri = URI(uri_string)
      if uri.userinfo
        options[:username] = uri.user unless options[:username]
        options[:password] = uri.password unless options[:password]
      end
      ((options[:retry_limit] || RETRY_LIMIT) + 1).times do |i|
        begin
          response = get_remote(uri, options)
          case
          when success?(response)
            return response.body
          when retryable?(response)
            raise HttpError.new(uri, response) if abort_retry?(i, options)
            delay_retry(i + 1)
            next
          else
            raise HttpError.new(uri, response)
          end
        rescue Timeout::Error => e
          raise e if abort_retry?(i, options)
          delay_retry(i + 1)
        end
      end
    end

    def get_remote(uri, options)
      request = Net::HTTP::Get.new(uri)
      request = prepare_auth(request, options) if options[:username] || options[:token]

      http = prepare_request(uri, options)
      response = perform_http_request(http, request, options)

      if response.is_a?(Net::HTTPRedirection)
        uri = URI(response.header['location'])
        req = Net::HTTP::Get.new(uri)
        req = prepare_auth(req, options) if options[:username] || options[:token]

        http = prepare_request(uri, options)
        response = perform_http_request(http, req, options)
      end
      response
    end

    def prepare_auth(request, options)
      request.basic_auth(options[:username], options[:password]) if options[:username]
      request['Authorization'] = "Bearer #{options[:token]}" if options[:token]
      request
    end

    def prepare_request(uri, options)
      http = Net::HTTP.new(uri.host, uri.port, :ENV)
      http.use_ssl = (uri.scheme == 'https')
      http.ca_file = ENV['SSL_CERT_FILE'] if ENV['SSL_CERT_FILE'] && ENV['SSL_CERT_FILE'] != ''
      http.ca_path = ENV['SSL_CERT_DIR'] if ENV['SSL_CERT_DIR'] && ENV['SSL_CERT_DIR'] != ''
      http.set_debug_output(Pact::Http::AuthorizationHeaderRedactor.new(Pact.configuration.output_stream)) if verbose?(options)

      if x509_certificate?
        http.cert = OpenSSL::X509::Certificate.new(x509_client_cert_file)
        http.key = OpenSSL::PKey::RSA.new(x509_client_key_file)
      end

      if disable_ssl_verification?
        if verbose?(options)
          Pact.configuration.output_stream.puts("SSL verification is disabled")
        end
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      http
    end

    def perform_http_request(http, request, options)
      http.start do |http|
        http.open_timeout = options[:open_timeout] || OPEN_TIMEOUT
        http.read_timeout = options[:read_timeout] || READ_TIMEOUT
        http.request(request)
      end
    end

    def success?(response)
      response.code.to_i == 200
    end

    def retryable?(response)
      (500...600).cover?(response.code.to_i)
    end

    def abort_retry?(count, options)
      count >= (options[:retry_limit] || RETRY_LIMIT)
    end

    def delay_retry(count)
      Kernel.sleep(2 ** count * 0.3)
    end

    def windows_safe(uri)
      uri.start_with?("http") ? uri : uri.gsub("\\", File::SEPARATOR)
    end

    def verbose?(options)
      options[:verbose] || ENV['VERBOSE'] == 'true'
    end

    def x509_certificate?
      ENV['X509_CLIENT_CERT_FILE'] && ENV['X509_CLIENT_CERT_FILE'] != '' &&
        ENV['X509_CLIENT_KEY_FILE'] && ENV['X509_CLIENT_KEY_FILE'] != ''
    end

    def x509_client_cert_file
      File.read(ENV['X509_CLIENT_CERT_FILE'])
    end

    def x509_client_key_file
      File.read(ENV['X509_CLIENT_KEY_FILE'])
    end

    def disable_ssl_verification?
      ENV['PACT_DISABLE_SSL_VERIFICATION'] == 'true' || ENV['PACT_BROKER_DISABLE_SSL_VERIFICATION'] == 'true'
    end
  end
end
