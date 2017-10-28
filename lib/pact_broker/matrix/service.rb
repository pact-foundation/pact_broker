require 'pact_broker/repositories'

module PactBroker
  module Matrix
    module Service

      extend self
      extend PactBroker::Repositories
      extend PactBroker::Services

      def find criteria
        matrix_repository.find criteria
      end

      def find_for_consumer_and_provider params
        matrix_repository.find_for_consumer_and_provider params[:consumer_name], params[:provider_name]
      end

      def find_compatible_pacticipant_versions criteria
        matrix_repository.find_compatible_pacticipant_versions criteria
      end

      def validate_selectors selectors
        error_messages = []

        selectors.each do | selector |
          if selector[:pacticipant_name].nil? && selector[:pacticipant_version_number].nil?
            error_messages << "Please specify the pacticipant name and version"
          elsif selector[:pacticipant_name].nil?
            error_messages << "Please specify the pacticipant name"
          elsif selector[:pacticipant_version_number].nil?
            error_messages << "Please specify the version for #{selector[:pacticipant_name]}"
          end
        end

        selectors.collect{ |selector| selector[:pacticipant_name] }.compact.each do | pacticipant_name |
          unless pacticipant_service.find_pacticipant_by_name(pacticipant_name)
            error_messages << "Pacticipant '#{pacticipant_name}' not found"
          end
        end

        if error_messages.empty?
          selectors.each do | selector |
            version = version_service.find_by_pacticipant_name_and_number(pacticipant_name: selector[:pacticipant_name], pacticipant_version_number: selector[:pacticipant_version_number])
            error_messages << "No pact or verification found for #{selector[:pacticipant_name]} version #{selector[:pacticipant_version_number]}" if version.nil?
          end
        end

        if selectors.size < 2
          error_messages << "Please provide 2 or more version selectors."
        end

        error_messages
      end
    end
  end
end
