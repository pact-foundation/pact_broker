require 'pact_broker/certificates/certificate'
require 'pact_broker/logging'
require 'openssl'

module PactBroker
  module Certificates
    module Service

      extend self
      extend PactBroker::Logging

      def cert_store
        cert_store = OpenSSL::X509::Store.new
        cert_store.set_default_paths
        find_all_certificates.each do | certificate |
          begin
            logger.debug("Loading certificate #{certificate.subject} in to cert store")
            cert_store.add_cert(certificate)
          rescue StandardError => e
            log_error e, "Error adding certificate object #{certificate.to_s} to store"
          end
        end
        cert_store
      end

      def find_all_certificates
        Certificate.collect do | certificate |
          cert_arr = certificate.content.split(/(-----END [^\-]+-----)/).each_slice(2).map(&:join)
          cert_arr.collect do |c|
            begin
              OpenSSL::X509::Certificate.new(c)
            rescue StandardError => e
              log_error e, "Error creating certificate object from certificate #{certificate.uuid} '#{certificate.description}'"
              nil
            end
          end
        end.flatten.compact
      end
    end
  end
end
