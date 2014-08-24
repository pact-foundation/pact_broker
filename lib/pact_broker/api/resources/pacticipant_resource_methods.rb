module PactBroker
  module Api
    module Resources

      module PacticipantResourceMethods

        def potential_duplicate_pacticipants? pacticipant_names
          messages = pacticipant_service.messages_for_potential_duplicate_pacticipants pacticipant_names, base_url
          if messages.any?
            response.body = messages.join("\n")
            response.headers['Content-Type'] = 'text/plain'
          end
          messages.any?
        end

      end
    end
  end
end