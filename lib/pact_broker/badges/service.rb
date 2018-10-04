require 'net/http'
require 'uri'
require 'pact_broker/project_root'
require 'pact_broker/logging'
require 'pact_broker/configuration'
require 'pact_broker/build_http_options'

module PactBroker
  module Badges
    module Service

      extend self
      include PactBroker::Logging

      SPACE_DASH_UNDERSCORE = /[\s_\-]/
      CACHE = {}

      def pact_verification_badge pact, label, initials, verification_status
        return static_svg(pact, verification_status) unless pact

        title = badge_title pact, label, initials
        status = badge_status verification_status
        color = badge_color verification_status

        dynamic_svg(title, status, color) || static_svg(pact, verification_status)
      end

      def clear_cache
        CACHE.clear
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
          parts = split_space_dash_underscore(name)
          parts = split_camel_case(name) if parts.size == 1
          return parts.collect{ |p| p[0] }.join.downcase if parts.size > 1
        end
        name.downcase
      end

      def split_space_dash_underscore name
        name.split(SPACE_DASH_UNDERSCORE)
      end

      def split_camel_case name
        name.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
            .tr('-', '_')
            .split('_')
      end

      def badge_status verification_status
        case verification_status
          when :success then "verified"
          when :failed then "failed"
          when :stale then "changed"
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
        return nil unless PactBroker.configuration.shields_io_base_url
        uri = build_uri(left_text, right_text, color)
        begin
          response = do_request(uri)
          response.code == '200' ? response.body : nil
        rescue StandardError => e
          logger.error "Error retrieving badge from #{uri} due to #{e.class} - #{e.message}"
          nil
        end
      end

      def build_uri left_text, right_text, color
        shield_base_url = PactBroker.configuration.shields_io_base_url
        path = "/badge/#{escape_text(left_text)}-#{escape_text(right_text)}-#{color}.svg"
        URI.parse(shield_base_url + path)
      end

      def escape_text text
        text.gsub(" ", "%20").gsub("-", "--").gsub("_", "__")
      end

      def do_request(uri)
        with_cache uri do
          request = Net::HTTP::Get.new(uri)
          options = {read_timeout: 3, open_timeout: 1, ssl_timeout: 1, continue_timeout: 1}
          options.merge! PactBroker::BuildHttpOptions.call(uri)

          Net::HTTP.start(uri.hostname, uri.port, :ENV, options) do |http|
            http.request request
          end
        end
      end

      def with_cache uri
        if !(response = CACHE[uri])
          response = yield
          if response.code == '200'
            CACHE[uri] = response
          end
        end
        response
      end

      def static_svg pact, verification_status
        file_name = case verification_status
          when :success then "pact-verified-brightgreen.svg"
          when :failed then "pact-failed-red.svg"
          when :stale then "pact-changed-orange.svg"
          else "pact-unknown-lightgrey.svg"
        end
        file_name = "pact_not_found-unknown-lightgrey.svg" unless pact
        File.read(PactBroker.project_root.join("public", "images", file_name))
      end
    end
  end
end
