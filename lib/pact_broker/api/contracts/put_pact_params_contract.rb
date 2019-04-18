require 'pact_broker/api/contracts/base_contract'

module PactBroker
  module Api
    module Contracts
      class PutPacticipantNameContract < BaseContract
        property :name
        property :name_in_pact
        property :pacticipant
        property :message_args

        validation do
          configure do
            config.messages_file = File.expand_path("../../../locale/en.yml", __FILE__)
          end

          required(:name).maybe
          required(:name_in_pact).maybe

          rule(name_in_path_matches_name_in_pact?: [:name, :name_in_pact]) do |name, name_in_pact|
            name_in_pact.filled?.then(name.eql?(value(:name_in_pact)))
          end
        end
      end

      class PutPactParamsContract < BaseContract
        property :consumer_version_number
        property :consumer, form: PutPacticipantNameContract
        property :provider, form: PutPacticipantNameContract

        validation do
          configure do
            config.messages_file = File.expand_path("../../../locale/en.yml", __FILE__)

            def valid_consumer_version_number?(value)
              return true if PactBroker.configuration.order_versions_by_date
              parsed_version_number = PactBroker.configuration.version_parser.call(value)
              !parsed_version_number.nil?
            end
          end

          required(:consumer_version_number).filled(:valid_consumer_version_number?)
        end
      end
    end
  end
end
