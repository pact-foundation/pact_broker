require 'pact_broker/repositories'

module PactBroker
  module Matrix
    module Service
      VERSION_SELECTOR_PATTERN = %r{(^[^/]+)/version/[^/]+$}.freeze

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
        selectors.each do | version_selector |
          if !(version_selector =~ VERSION_SELECTOR_PATTERN)
            error_messages << "Invalid version selector '#{version_selector}'. Format must be <pacticipant_name>/version/<version>"
          end
        end

        selectors.each do | version_selector |
          if match = version_selector.match(VERSION_SELECTOR_PATTERN)
            pacticipant_name = match[1]
            unless pacticipant_service.find_pacticipant_by_name(pacticipant_name)
              error_messages << "Pacticipant '#{pacticipant_name}' not found"
            end
          end
        end

        if error_messages.empty?
          selected_versions = version_service.find_versions_by_selector(selectors)
          if selected_versions.any?(&:nil?)
            selected_versions.each_with_index do | selected_version, i |
              error_messages << "No pact or verification found for #{selectors[i]}" if selected_version.nil?
            end
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
