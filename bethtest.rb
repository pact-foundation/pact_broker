require 'openssl'
require 'uri'
require 'net/http'

uri = URI('https://self-signed.badssl.com')
downloaded_cert_path = '/tmp/downloaded_cert.pem'

puts `openssl s_client -showcerts -servername #{uri.host} -connect #{uri.host}:#{uri.port} </dev/null 2>/dev/null|openssl x509 -text`
command = "openssl s_client -showcerts -servername #{uri.host} -connect #{uri.host}:#{uri.port} </dev/null 2>/dev/null|openssl x509 -outform PEM > #{downloaded_cert_path}"
puts command
puts `#{command}`


cert_store = OpenSSL::X509::Store.new
puts "Adding certificate #{downloaded_cert_path}"
cert_store.add_file(downloaded_cert_path)

req = Net::HTTP::Get.new(uri)

options = {
  :use_ssl => uri.scheme == 'https',
  verify_mode: OpenSSL::SSL::VERIFY_PEER,
  cert_store: cert_store
}

response = Net::HTTP.start(uri.hostname, uri.port, options) do |http|
  http.request req
end

puts response