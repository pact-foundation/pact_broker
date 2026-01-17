require 'pact/mock_service/request_handlers/base_administration_request_handler'
require 'pact/consumer_contract/consumer_contract_writer'

module Pact
  module MockService
    module RequestHandlers
      class PactPost < BaseAdministrationRequestHandler

        attr_accessor :consumer_contract, :verified_interactions, :default_options, :session

        def initialize name, logger, session
          super name, logger
          @verified_interactions = session.verified_interactions
          @default_options = {}
          @default_options.merge!(session.consumer_contract_details)
          @session = session
        end

        def request_path
          '/pact'
        end

        def request_method
          'POST'
        end

        def respond env
          body = env['rack.input'].read
          consumer_contract_details = body.size > 0 ? JSON.parse(body, symbolize_names: true) : {}
          consumer_contract_params = default_options.merge(consumer_contract_details.merge(interactions: verified_interactions))
          consumer_contract_writer = ConsumerContractWriter.new(consumer_contract_params, logger)
          session.record_pact_written
          json_response(consumer_contract_writer.write)
        end
      end
    end
  end
end
