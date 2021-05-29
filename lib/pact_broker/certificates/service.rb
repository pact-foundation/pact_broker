require 'pact_broker/certificates/certificate'
require 'pact_broker/logging'
require 'openssl'

module PactBroker
  module Certificates
    module Service

      extend self
      extend PactBroker::Logging
      include PactBroker::Logging

      def cert_store
        cert_store = OpenSSL::X509::Store.new
        cert_store.set_default_paths
        find_all_certificates.each do | certificate |
          begin
            logger.debug("Loading certificate #{certificate.subject} in to cert store")
            cert_store.add_cert(certificate)
          rescue StandardError => e
            logger.warn("Error adding certificate object #{certificate} to store", e)
          end
        end
        cert_store
      end

      def find_all_certificates
        Certificate.collect do | certificate |
          cert_arr = certificate.content.split(/(-----END [^\-]+-----)/).each_slice(2).map(&:join).map(&:strip).select{|s| !s.empty?}
          cert_arr.collect do |c|
            begin
              OpenSSL::X509::Certificate.new(c)
            rescue StandardError => e
              logger.warn("Error creating certificate object from certificate #{certificate.uuid} '#{certificate.description}'", e)
              nil
            end
          end
        end.flatten.compact
      end
    end
  end
end
