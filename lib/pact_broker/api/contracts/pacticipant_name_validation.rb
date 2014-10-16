module PactBroker
  module Api
    module Contracts
      module PacticipantNameValidation

        include PactBroker::Messages

        def name_in_pact_present
          unless name_in_pact
            errors.add(:'name', validation_message('pact_missing_pacticipant_name', pacticipant: pacticipant))
          end
        end

        def name_not_blank
          if blank? name
            errors.add(:'name', validation_message('blank'))
          end
        end

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
