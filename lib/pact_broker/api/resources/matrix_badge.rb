require 'pact_broker/api/resources/badge'

module PactBroker
  module Api
    module Resources
      class MatrixBadge < Badge

        private

        def latest_verification
          @latest_verification ||= begin
            matrix_row = matrix_service.find_for_consumer_and_provider_with_tags(identifier_from_path)
            if matrix_row && matrix_row[:verification_id]
              verification_service.find_by_id(matrix_row[:verification_id])
            end
          end
        end
      end
    end
  end
end
