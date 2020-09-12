require 'net/http'
require 'uri'
require 'pact_broker/project_root'
require 'pact_broker/logging'
require 'pact_broker/configuration'
require 'pact_broker/build_http_options'
require 'erb'

module PactBroker
  module Badges
    module Service

      extend self
      include PactBroker::Logging

      SPACE_DASH_UNDERSCORE = /[\s_\-]/
      CACHE = {}

      def can_provide_badge_using_redirect?
        PactBroker.configuration.badge_provider_mode == :redirect && !!PactBroker.configuration.shields_io_base_url
      end

      def pact_verification_badge pact, label, initials, pseudo_branch_verification_status, metadata = {}
        return static_svg(pact, pseudo_branch_verification_status) unless pact

        dynamic_svg(pact, label, initials, pseudo_branch_verification_status, metadata) || static_svg(pact, pseudo_branch_verification_status)
      end

      def pact_verification_badge_url(pact, label, initials, pseudo_branch_verification_status, metadata = {})
        title = badge_title(pact, label, initials, metadata)
        status = badge_status(pseudo_branch_verification_status)
        color = badge_color(pseudo_branch_verification_status)
        build_shield_io_uri(title, status, color)
      end

      def clear_cache
        CACHE.clear
      end

      private

      def badge_title pact, label, initials, metadata
        return 'pact not found' if pact.nil?
        consumer_name = prepare_name(pact.consumer_name, initials, metadata[:consumer_tag])
        provider_name = prepare_name(pact.provider_name, initials, metadata[:provider_tag])
        title = case (label || '').downcase
          when 'consumer' then consumer_name
          when 'provider' then provider_name
          else "#{consumer_name}/#{provider_name}"
        end
        "#{title} pact".downcase
      end

      def prepare_name name, initials, tag = nil
        tag_suffix = tag ? " (#{tag})" : ''
        if initials
          parts = split_space_dash_underscore(name)
          parts = split_camel_case(name) if parts.size == 1
          return parts.collect{ |p| p[0] }.join.downcase + tag_suffix if parts.size > 1
        end
        name.downcase + tag_suffix
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

      def badge_status pseudo_branch_verification_status
        case pseudo_branch_verification_status
          when :success then "verified"
          when :failed then "failed"
          when :stale then "changed"
          else "unknown"
        end
      end

      def badge_color pseudo_branch_verification_status
        case pseudo_branch_verification_status
          when :success then "brightgreen"
          when :failed then "red"
          when :stale then "orange"
          else "lightgrey"
        end
      end

      def dynamic_svg pact, label, initials, pseudo_branch_verification_status, metadata
        return nil unless PactBroker.configuration.shields_io_base_url
        uri = pact_verification_badge_url(pact, label, initials, pseudo_branch_verification_status, metadata)
        begin
          response = do_request(uri)
          response.code == '200' ? response.body : nil
        rescue Net::OpenTimeout => e
          logger.warn "Timeout retrieving badge from #{uri} #{e.class} - #{e.message}"
          nil
        rescue StandardError => e
          logger.warn("Error retrieving badge from #{uri}", e)
          nil
        end
      end

      def build_shield_io_uri left_text, right_text, color
        shield_base_url = PactBroker.configuration.shields_io_base_url
        path = "/badge/#{escape_text(left_text)}-#{escape_text(right_text)}-#{color}.svg"
        URI.parse(shield_base_url + path)
      end

      def escape_text text
        ERB::Util.url_encode(text.gsub("-", "--").gsub("_", "__"))
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

      def static_svg pact, pseudo_branch_verification_status
        file_name = case pseudo_branch_verification_status
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
