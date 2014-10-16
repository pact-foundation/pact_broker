require 'pact_broker/json'
require 'pact_broker/constants'
require 'ostruct'

module PactBroker
  module Pacts
    class PactParams < Hash

      def initialize attributes
        merge!(attributes)
      end

      def self.from_post_request request
        json_content = request.body.to_s
        pact_hash = begin
          JSON.parse(json_content, PACT_PARSING_OPTIONS)
        rescue
          {}
        end

        new(
          consumer_name: pact_hash.fetch('consumer',{})['name'],
          provider_name: pact_hash.fetch('provider',{})['name'],
          consumer_version_number: request.headers[CONSUMER_VERSION_HEADER],
          consumer_name_in_pact: pact_hash.fetch('consumer',{})['name'],
          provider_name_in_pact: pact_hash.fetch('provider',{})['name'],
          json_content: json_content
        )
      end

      def self.from_request request, path_info
        json_content = request.body.to_s
        pact_hash = begin
          JSON.parse(json_content, PACT_PARSING_OPTIONS)
        rescue
          {}
        end

        new(
          consumer_name: path_info.fetch(:consumer_name),
          provider_name: path_info.fetch(:provider_name),
          consumer_version_number: path_info.fetch(:consumer_version_number),
          consumer_name_in_pact: pact_hash.fetch('consumer',{})['name'],
          provider_name_in_pact: pact_hash.fetch('provider',{})['name'],
          json_content: json_content
        )
      end

      def pacticipant_names
        [consumer_name, provider_name]
      end

      def consumer_name
        self[:consumer_name]
      end

      def provider_name
        self[:provider_name]
      end

      def consumer_version_number
        self[:consumer_version_number]
      end

      def json_content
        self[:json_content]
      end

      def consumer_name_in_pact
        self[:consumer_name_in_pact]
      end

      def provider_name_in_pact
        self[:provider_name_in_pact]
      end

      def consumer
        OpenStruct.new(
          name: consumer_name,
          name_in_pact: consumer_name_in_pact,
          pacticipant: 'consumer'
        )
      end

      def provider
        OpenStruct.new(
          name: provider_name,
          name_in_pact: provider_name_in_pact,
          pacticipant: 'provider'
        )
      end

    end
  end
end
