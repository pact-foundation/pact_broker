require "pact_broker/services"

module PactBroker
  class BuildHttpOptions
    extend PactBroker::Services

    def self.call uri, disable_ssl_verification: false
      uri = URI(uri)
      options = {}

      if uri.scheme == "https"
        options[:use_ssl] = true
        options[:cert_store] = cert_store
        if disable_ssl_verification
          options[:verify_mode] = OpenSSL::SSL::VERIFY_NONE
        else
          options[:verify_mode] = OpenSSL::SSL::VERIFY_PEER
        end
      end
      options
    end

    def self.cert_store
      certificate_service.cert_store
    end
  end
end

