require 'reform'
require 'reform/contract'

module PactBroker
  module Api
    module Contracts

      class PacticipantNameContract < Reform::Contract
        property :name
        property :name_in_pact
        property :pacticipant
        property :message_args


        include PactBroker::Messages

        def blank? string
          string && string.strip.empty?
        end

        def empty? string
          string.nil? || blank?(string)
        end
      end
    end
  end
end
