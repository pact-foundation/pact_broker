require 'net/http'
require 'uri'
require 'pact_broker/project_root'
require 'pact_broker/logging'

module PactBroker
  module Badges
    module Service

      extend self
      include PactBroker::Logging

      # TODO timeout

      def pact_verification_badge pact, label, initials, verification_status
        return static_svg(pact, verification_status) unless pact

        title = badge_title pact, label, initials
        status = badge_status verification_status
        color = badge_color verification_status

        dynamic_svg(title, status, color) || static_svg(pact, verification_status)
      end

      private

      def badge_title pact, label, initials
        title = case (label || '').downcase
          when 'consumer' then prepare_name(pact.consumer_name, initials)
          when 'provider' then prepare_name(pact.provider_name, initials)
          else "#{prepare_name(pact.consumer_name, initials)}%2F#{prepare_name(pact.provider_name, initials)}"
        end
        "#{title} pact".downcase
      end

      def prepare_name name, initials
        if initials
          parts = name.split(/[\s_\-]/)
          if parts.size > 1
            return parts.collect{ |p| p[0] }.join.downcase
          end
        end
        name.downcase
      end

      def badge_status verification_status
        case verification_status
          when :success then "verified"
          when :failed then "failed"
          else "unknown"
        end
      end

      def badge_color verification_status
        case verification_status
          when :success then "brightgreen"
          when :failed then "red"
          when :stale then "orange"
          else "lightgrey"
        end
      end

      def dynamic_svg left_text, right_text, color
        uri = build_uri(left_text, right_text, color)
        begin
          response = do_request(uri)
          response.code == '200' ? response.body : nil
        rescue StandardError => e
          log_error e, "Error retrieving badge from #{uri}"
          nil
        end
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

      def static_svg pact, verification_status
        file_name = case verification_status
          when :success then "pact-verified-brightgreen.svg"
          when :failed then "pact-failed-red.svg"
          when :stale then "pact-unknown-orange.svg"
          else "pact-unknown-lightgrey.svg"
        end
        file_name = "pact_not_found-unknown-lightgrey.svg" unless pact
        File.read(PactBroker.project_root.join("public", "images", file_name))
      end
    end
  end
end
