require "pact_broker/api/contracts/base_contract"

module PactBroker
  module Api
    module Contracts
      class PutPacticipantNameContract < BaseContract
        property :name
        property :name_in_pact
        property :pacticipant
        property :message_args

        validation do
          schema do
            configure do
              config.messages.load_paths << File.expand_path("../../../locale/en.yml", __FILE__)
            end

            required(:name).maybe(:str?)
            required(:name_in_pact).maybe(:str?)
          end

          rule(:name, :name_in_pact) do
            # Original:
            # rule(name_in_path_matches_name_in_pact?: [:name, :name_in_pact]) do |name, name_in_pact|
            #   name_in_pact.filled?.then(name.eql?(value(:name_in_pact)))
            key.failure(:name_in_path_matches_name_in_pact?) if key?(:name_in_pact) &&
              !values[:name_in_pact].eql?(values[:name])
          end
        end
      end

      class PutPactParamsContract < BaseContract
        property :consumer_version_number
        property :consumer, form: PutPacticipantNameContract
        property :provider, form: PutPacticipantNameContract

        def self.valid_consumer_version_number?(value)
          return true if PactBroker.configuration.order_versions_by_date
          parsed_version_number = PactBroker.configuration.version_parser.call(value)
          !parsed_version_number.nil?
        end

        ::Dry::Validation.register_macro(:valid_consumer_version_number?) do
          key.failure(text: :valid_consumer_version_number?, value: value) unless
            PutPactParamsContract.valid_consumer_version_number?(value)
        end

        validation do
          schema do
            configure do
              config.messages.load_paths << File.expand_path("../../../locale/en.yml", __FILE__)
            end

            required(:consumer_version_number).filled(:str?)
          end

          rule(:consumer_version_number).validate(:valid_consumer_version_number?)
        end
      end
    end
  end
end
