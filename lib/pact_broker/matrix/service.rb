require 'pact_broker/repositories'
require 'pact_broker/matrix/row'

module PactBroker
  module Matrix
    module Service

      extend self
      extend PactBroker::Repositories
      extend PactBroker::Services

      def refresh params, &block
        matrix_repository.refresh(params, &block)
      end

      def refresh_tags params, &block
        matrix_repository.refresh_tags(params, &block)
      end

      def find criteria, options = {}
        matrix_repository.find criteria, options
      end

      def find_for_consumer_and_provider params
        matrix_repository.find_for_consumer_and_provider params[:consumer_name], params[:provider_name]
      end

      def find_for_consumer_and_provider_with_tags params
        consumer_criteria = {
          pacticipant_name: params[:consumer_name],
          tag: params[:tag],
          latest: true
        }
        provider_criteria = {
          pacticipant_name: params[:provider_name],
          tag: params[:provider_tag],
          latest: true
        }
        selectors = [consumer_criteria, provider_criteria]
        options = { latestby: 'cvpv' }
        if validate_selectors(selectors).empty?
          matrix_repository.find(selectors, options).first
        else
          nil
        end
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
              error_messages << "A version number and latest flag cannot both be specified for #{s[:pacticipant_name]}"
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
              version = version_service.find_by_pacticipant_name_and_latest_tag(s[:pacticipant_name], s[:tag])
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
