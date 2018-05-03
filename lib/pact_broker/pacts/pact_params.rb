require 'pact_broker/json'
require 'pact_broker/constants'
require 'ostruct'

module PactBroker
  module Pacts
    class PactParams < Hash

      def initialize attributes
        merge!(attributes)
      end

      def self.from_path_info path_info
        new(
          consumer_name: path_info.fetch(:consumer_name),
          provider_name: path_info.fetch(:provider_name),
          consumer_version_number: path_info[:consumer_version_number],
          revision_number: path_info[:revision_number],
          pact_version_sha: path_info[:pact_version_sha]
        )
      end

      def self.from_request request, path_info
        json_content = request.body.to_s
        parsed_content = begin
          JSON.parse(json_content, PACT_PARSING_OPTIONS)
        rescue
          {}
        end

        consumer_name_in_pact = parsed_content.is_a?(Hash) ? parsed_content.fetch('consumer',{})['name'] : nil
        provider_name_in_pact = parsed_content.is_a?(Hash) ? parsed_content.fetch('provider',{})['name'] : nil

        new(
          consumer_name: path_info.fetch(:consumer_name),
          provider_name: path_info.fetch(:provider_name),
          revision_number: path_info[:revision_number],
          consumer_version_number: path_info[:consumer_version_number],
          pact_version_sha: path_info[:pact_version_sha],
          consumer_name_in_pact: consumer_name_in_pact,
          provider_name_in_pact: provider_name_in_pact,
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

      def pact_version_sha
        self[:pact_version_sha]
      end

      def revision_number
        self[:revision_number]
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
