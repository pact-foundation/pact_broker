# require "net/http"
# require "openssl"

# TEST_URL = 'https://localhost:4444'
# TEST_CERTIFICATE = "-----BEGIN CERTIFICATE-----
# MIIDZDCCAkygAwIBAgIBATANBgkqhkiG9w0BAQsFADBCMRMwEQYKCZImiZPyLGQB
# GRYDb3JnMRkwFwYKCZImiZPyLGQBGRYJcnVieS1sYW5nMRAwDgYDVQQDDAdSdWJ5
# IENBMCAXDTE4MDUxNzA3NDQzNVoYDzIxMTgwNDIzMDc0NDM1WjBCMRMwEQYKCZIm
# iZPyLGQBGRYDb3JnMRkwFwYKCZImiZPyLGQBGRYJcnVieS1sYW5nMRAwDgYDVQQD
# DAdSdWJ5IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1tcEnh7S
# iiL46HNfx5LkGxBZ9Dn7tUm6CKlPzykjlCGZ9a5VpnZxwEK5LkIvbMiBz8UjhcVh
# 8pUghbyvwSHdtiMDNU4zpKIgrTXZ/tiqctgYYSFbtEtE17VrVM8JZFSxzLSJEvEZ
# rhkOqeVEGJJY28taItbjxfHYkTlQYTjn6tA18KT13nGAUMEoC0HZTHYr2nCY7MzI
# cEISvm5PP7gXKHrOfpbm+E3qMm9kyDQLkez8iGfq2aGSshuT4mcAvxq5dS6TsPSy
# ZphnfHw3THqgBrR8Bw1tMhsnLhD96Miy5sRnY2gQEAQngccLZ/F6ls6a+5Adka2o
# zFmJVZXhHbVeRwIDAQABo2MwYTAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQE
# AwIBBjAdBgNVHQ4EFgQUBX8ZMupoE2NMwyE1kdlVptFti/kwHwYDVR0jBBgwFoAU
# BX8ZMupoE2NMwyE1kdlVptFti/kwDQYJKoZIhvcNAQELBQADggEBAIxS0jDTRC9R
# mxsr2j/o9oQvRi5+74qDlXs7YzbQ1V7dy++g48St6Yjk4xfdGdgAS8IrS9vIRKUy
# jnlwUklnkvoWk2DKF9NFA32c1mxZhau5QGu3VH7pgmcWQawXttqpgHbSLEDAf9wU
# jgTRdL8LxMIf6xy2uPL8GZWFbmdU5HOb3czS1drouE0U3ZI+1uzAlR3vqGo0Mvhd
# MwYBodIJlWa0mXKMnfZxYLtiv7m5H5I2zBfget3+3ovuN79Zn6RA3ecnxn75jalA
# R6MNlS/tzpXcS/gwnSKrwHSjb1V+B4Q96EsfulWC2UpTa0WTxngyiqtp6GU6RZva
# jHT1Ty2CglM=
# -----END CERTIFICATE-----
# "

# def split_certificate_chain(content)
#   content.split(/(-----END [^\-]+-----)/).each_slice(2).map(&:join).map(&:strip).select{|s| !s.empty?}
# end

# def build_cert_store
#   cert_store = OpenSSL::X509::Store.new
#   split_certificate_chain(TEST_CERTIFICATE).each do | content |
#     cert_store.add_cert(OpenSSL::X509::Certificate.new(content))
#   end
#   cert_store
# end

# uri = URI.parse(TEST_URL)
# http = Net::HTTP.new(uri.host, uri.port)
# http.use_ssl = true
# http.cert_store = build_cert_store
# http.verify_mode = OpenSSL::SSL::VERIFY_PEER
# data = http.get(uri.request_uri)
# puts data


require "pact_broker/pacts/create_formatted_diff"
require "pact_broker/project_root"
require 'flamegraph'

content_1 = File.read(PactBroker.project_root.join("b17279757b28c9319366bb129e3eb75bc1c2fe95.json"))
content_2 = File.read(PactBroker.project_root.join("c31600ae411a29d136acb1e98d6d91841f70f3e6.json"))
#content_1 = File.read(PactBroker.project_root.join("pact_broker_client-pact_broker.json"))
#content_2 = File.read(PactBroker.project_root.join("lib/pact_broker/db/seed/pact_3.json"))

require 'timeout'
status = Timeout::timeout(5) {
  PactBroker::Pacts::CreateFormattedDiff.call(
    content_1,
    content_2
  )
}

# Flamegraph.generate("bethtemp.html") do
#   PactBroker::Pacts::CreateFormattedDiff.call(
#     content_1,
#     content_2
#   )
# end
