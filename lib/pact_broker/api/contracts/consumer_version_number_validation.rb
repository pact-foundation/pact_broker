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
          begin
            Versionomy.parse(consumer_version_number)
            false
          rescue Versionomy::Errors::ParseError => e
            true
          end
        end

      end
    end
  end
end
