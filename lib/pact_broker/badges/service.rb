require 'net/http'
require 'uri'

module PactBroker

  module Badges
    module Service

      extend self

      def pact_verification_badge pacticipant_name, verification_status
        status = case verification_status
          when :never, :stale then "unknown"
          when :success then "verified"
          when :failed then "failed"
        end

        color = case verification_status
          when :never then "lightgrey"
          when :success then "brightgreen"
          when :failed then "red"
          when :stale then "orange"
        end
        svg  "#{pacticipant_name} Pact", status, color
      end

      private

      def svg left_text, right_text, color
        uri = build_uri(left_text, right_text, color)
        do_request(uri).body
      end

      def build_uri left_text, right_text, color
        shield_base_url = "https://img.shields.io"
        path = "/badge/#{escape_text(left_text)}-#{escape_text(right_text)}-#{color}.svg"
        URI.parse(shield_base_url + path)
      end

      def escape_text text
        text.gsub(" ", "%20").gsub("-", "--").gsub("_", "__")
      end

      def do_request(uri)
        request = Net::HTTP::Get.new(uri)
        Net::HTTP.start(uri.hostname, uri.port,
          :use_ssl => uri.scheme == 'https') do |http|
          http.request request
        end
      end
    end
  end
end
