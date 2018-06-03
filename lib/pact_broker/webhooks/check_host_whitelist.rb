module PactBroker
  module Webhooks
    class CheckHostWhitelist

      def self.call(host, whitelist = PactBroker.configuration.webhook_host_whitelist)
        whitelist.select{ | whitelist_host | match?(host, whitelist_host) }
      end

      def self.match?(host, whitelist_host)
        if whitelist_host.is_a?(Regexp)
          host =~ whitelist_host
        else
          begin
            IPAddr.new(whitelist_host) === IPAddr.new(host)
          rescue IPAddr::Error
            host == whitelist_host
          end
        end
      end
    end
  end
end
