require 'openssl'

module PactBroker
  module Webhooks
    class CheckHostWhitelist

      def self.call(host, whitelist = PactBroker.configuration.webhook_host_whitelist)
        whitelist.select{ | whitelist_host | match?(host, whitelist_host) }
      end

      def self.match?(host, whitelist_host)
        if parse_ip_address(host)
          ip_address_matches_range(host, whitelist_host)
        elsif whitelist_host.is_a?(Regexp)
          host_matches_regexp(host, whitelist_host)
        elsif whitelist_host.start_with?("*")
          OpenSSL::SSL.verify_hostname(host, whitelist_host)
        else
          host == whitelist_host
        end
      end

      def self.parse_ip_address(addr)
        IPAddr.new(addr)
      rescue IPAddr::Error
        nil
      end

      def self.ip_address_matches_range(host, maybe_whitelist_range)
        parse_ip_address(maybe_whitelist_range) === parse_ip_address(host)
      end

      def self.host_matches_regexp(host, whitelist_regexp)
        host =~ whitelist_regexp
      end

      def self.host_matches_domain_with_wildcard(host, whitelist_domain)
        OpenSSL::SSL.verify_hostname(host, whitelist_domain)
      end
    end
  end
end
