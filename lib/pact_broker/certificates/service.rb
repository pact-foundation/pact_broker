require "pact_broker/certificates/certificate"
require "pact_broker/logging"
require "openssl"

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
        certificates_from_database + certificates_from_config
      end

      def certificates_from_database
        Certificate.collect do | certificate |
          split_certificate_chain(certificate.content).collect do |c|
            begin
              OpenSSL::X509::Certificate.new(c)
            rescue StandardError => e
              logger.warn("Error creating certificate object from certificate #{certificate.uuid} '#{certificate.description}'", e)
              nil
            end
          end
        end.flatten.compact
      end

      def certificates_from_config
        PactBroker.configuration.webhook_certificates.select{| c| c[:content] || c[:path] }.collect do | certificate_config, i |
          load_certificate_config(certificate_config, i)
        end.flatten.compact
      end

      def load_certificate_config(certificate_config, i)
        begin
          content = certificate_config[:content] || File.read(certificate_config[:path])
          split_certificate_chain(content).collect do |c|
            begin
              OpenSSL::X509::Certificate.new(c)
            rescue StandardError => e
              logger.warn("Error creating certificate object from webhook_certificate at index #{i} with description #{certificate_config[:description]}", e)
              nil
            end
          end
        rescue StandardError => e
          logger.warn("Error loading webhook_certificate at index #{i} with description #{certificate_config[:description]}", e)
          nil
        end
      end

      def split_certificate_chain(content)
        content.split(/(-----END [^\-]+-----)/).each_slice(2).map(&:join).map(&:strip).select{|s| !s.empty?}
      end
    end
  end
end
