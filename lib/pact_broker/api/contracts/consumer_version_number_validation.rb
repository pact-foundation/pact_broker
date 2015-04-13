module PactBroker
  module Api
    module Contracts
      module ConsumerVersionNumberValidation

        include PactBroker::Messages

        def consumer_version_number_present
          unless consumer_version_number
            errors.add(:base, validation_message('consumer_version_number_missing'))
          end
        end

        def consumer_version_number_valid
          if consumer_version_number && invalid_consumer_version_number?
            errors.add(:base, consumer_version_number_validation_message)
          end
        end

        def invalid_consumer_version_number?
          parsed_version_number = PactBroker.configuration.version_parser.call consumer_version_number
          parsed_version_number.nil?
        end
      end
    end
  end
end
