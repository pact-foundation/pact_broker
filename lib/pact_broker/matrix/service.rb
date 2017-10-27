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

        selectors.each do | pacticipant_name, version |
          if pacticipant_name.nil? && version.nil?
            error_messages << "Please specify the pacticipant name and version"
          elsif pacticipant_name.nil?
            error_messages << "Please specify the pacticipant name"
          elsif version.nil?
            error_messages << "Please specify the version for #{pacticipant_name}"
          end
        end

        if selectors.values.any?(&:nil?)
          error_messages << "Please specify the pacticipant version"
        end

        selectors.keys.compact.each do | pacticipant_name |
          unless pacticipant_service.find_pacticipant_by_name(pacticipant_name)
            error_messages << "Pacticipant '#{pacticipant_name}' not found"
          end
        end

        if error_messages.empty?
          selectors.each do | pacticipant_name, version_number |
            version = version_service.find_by_pacticipant_name_and_number(pacticipant_name: pacticipant_name, pacticipant_version_number: version_number)
            error_messages << "No pact or verification found for #{pacticipant_name} version #{version_number}" if version.nil?
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
