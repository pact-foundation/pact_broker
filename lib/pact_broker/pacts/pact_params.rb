require 'pact_broker/json'
require 'pact_broker/constants'
require 'pact_broker/api/pact_broker_urls'
require 'ostruct'

module PactBroker
  module Pacts
    class PactParams < Hash

      extend PactBroker::Api::PactBrokerUrls

      def initialize attributes
        merge!(attributes)
      end

      def self.from_request request, path_info, base_url
        json_content = request.body.to_s
        parsed_content = begin
          JSON.parse(json_content, PACT_PARSING_OPTIONS)
        rescue
          {}
        end

        consumer_name_in_pact = parsed_content.is_a?(Hash) ? parsed_content.fetch('consumer',{})['name'] : nil
        provider_name_in_pact = parsed_content.is_a?(Hash) ? parsed_content.fetch('provider',{})['name'] : nil

        pact_params = new(
          consumer_name: path_info.fetch(:consumer_name),
          provider_name: path_info.fetch(:provider_name),
          consumer_version_number: path_info.fetch(:consumer_version_number),
          consumer_name_in_pact: consumer_name_in_pact,
          provider_name_in_pact: provider_name_in_pact,
          json_content: json_content
        )
        pact_params[:pact_version_url] = pact_url_from_params(base_url, pact_params)
        pact_params
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

      def pact_version_url
        self[:pact_version_url]
      end

      def consumer
        PacticipantName.new(consumer_name, consumer_name_in_pact, 'consumer')
      end

      def provider
        PacticipantName.new(provider_name, provider_name_in_pact, 'provider')
      end

      class PacticipantName < Struct.new(:name, :name_in_pact, :pacticipant)
        def message_args
          {
            name: name,
            name_in_pact: name_in_pact,
            pacticipant: pacticipant
          }
        end
      end

    end
  end
end
