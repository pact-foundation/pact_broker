module PactBroker
  module Webhooks
    class CheckHostBlacklist

      def self.call(host, blacklist = PactBroker.configuration.webhook_host_blacklist)
        blacklist.select{ | blacklist_host | match?(host, blacklist_host) }
      end

      def self.match?(host, blacklist_host)
        begin
          IPAddr.new(blacklist_host) === IPAddr.new(host)
        rescue IPAddr::Error
          if blacklist_host.is_a?(Regexp)
            host =~ blacklist_host
          else
            host == blacklist_host
          end
        end
      end
    end
  end
end
