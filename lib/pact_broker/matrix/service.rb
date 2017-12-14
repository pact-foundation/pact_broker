require 'pact_broker/repositories'

module PactBroker
  module Matrix
    module Service

      extend self
      extend PactBroker::Repositories
      extend PactBroker::Services

      def find criteria, options = {}
        matrix_repository.find criteria, options
      end

      def find_for_consumer_and_provider params
        matrix_repository.find_for_consumer_and_provider params[:consumer_name], params[:provider_name]
      end

      def find_compatible_pacticipant_versions criteria
        matrix_repository.find_compatible_pacticipant_versions criteria
      end

      def validate_selectors selectors
        error_messages = []

        selectors.each do | s |
          if s[:pacticipant_name].nil?
            error_messages << "Please specify the pacticipant name"
          else
            if s.key?(:pacticipant_version_number) && s.key?(:latest)
              error_messages << "A version and latest flag cannot both be specified for #{s[:pacticipant_name]}"
            end

            if s.key?(:tag) && !s.key?(:latest)
              error_messages << "Querying for all versions with a tag is not currently supported. The latest=true flag must be specified when a tag is given."
            end
          end
        end

        selectors.collect{ |selector| selector[:pacticipant_name] }.compact.each do | pacticipant_name |
          unless pacticipant_service.find_pacticipant_by_name(pacticipant_name)
            error_messages << "Pacticipant #{pacticipant_name} not found"
          end
        end

        if error_messages.empty?
          selectors.each do | s |
            if s[:pacticipant_version_number]
              version = version_service.find_by_pacticipant_name_and_number(pacticipant_name: s[:pacticipant_name], pacticipant_version_number: s[:pacticipant_version_number])
              error_messages << "No pact or verification found for #{s[:pacticipant_name]} version #{s[:pacticipant_version_number]}" if version.nil?
            elsif s[:tag]
              version = version_service.find_by_pacticpant_name_and_latest_tag(s[:pacticipant_name], s[:tag])
              error_messages << "No version of #{s[:pacticipant_name]} found with tag #{s[:tag]}" if version.nil?
            end
          end
        end

        if selectors.size == 0
          error_messages << "Please provide 1 or more version selectors."
        end

        error_messages
      end
    end
  end
end
