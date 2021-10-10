require "pact_broker/hash_refinements"
require "pact_broker/pacts/metadata"

module PactBroker
  module Api
    module Resources
      module MetadataResourceMethods
        using PactBroker::HashRefinements

        def pact_params
          @pact_params ||= PactBroker::Pacts::PactParams.from_request(request, maybe_consumer_version_number_param.merge(identifier_from_path))
        end

        def maybe_consumer_version_number_param
          if metadata[:consumer_version_number]
            metadata.slice(:consumer_version_number)
          elsif metadata_consumer_version_numbers&.any?
            {
              consumer_version_number: consumer_versions_from_metadata.last&.number
            }
          else
            {}
          end
        end

        def metadata
          @metadata ||= PactBroker::Pacts::Metadata.parse_metadata(PactBrokerUrls.decode_pact_metadata(identifier_from_path[:metadata]))
        end

        def metadata_consumer_version_numbers
          @metadata_consumer_version_numbers ||= begin
            if metadata[:consumer_version_selectors].is_a?(Array)
              metadata[:consumer_version_selectors].collect{ | selector | selector[:consumer_version_number] }.compact.uniq
            elsif metadata[:consumer_version_number]
              [metadata[:consumer_version_number]]
            else
              nil
            end
          end
        end

        def consumer_versions_from_metadata
          @consumer_versions_from_metadata ||= begin
            if metadata_consumer_version_numbers
              metadata_consumer_version_numbers.collect do | consumer_version_number |
                version_service.find_by_pacticipant_name_and_number(pacticipant_name: identifier_from_path[:consumer_name], pacticipant_version_number: consumer_version_number)
              end.compact.sort_by(&:order)
            end
          end
        end
      end
    end
  end
end
