require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/matrix_decorator'
require 'cgi'

module PactBroker
  module Api
    module Resources
      class Matrix < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET"]
        end

        def malformed_request?
          error_messages = matrix_service.validate_selectors(selectors)
          if error_messages.any?
            set_json_validation_error_messages error_messages
            true
          else
            false
          end
        end

        def to_json
          criteria = selected_versions.each_with_object({}) { | version, hash | hash[version.pacticipant.name] = version.number }
          lines = matrix_service.find_compatible_pacticipant_versions(criteria)
          PactBroker::Api::Decorators::MatrixPactDecorator.new(lines).to_json(user_options: { base_url: base_url })
        end

        def selectors
          @selectors ||= CGI.parse(CGI.unescape(request.uri.query))['selectors[]']
        end

        def version_selectors
          @version_selectors ||= selectors.select{ | selector| selector.include?("/version/") }
        end

        def selected_versions
          @selected_versions ||= version_service.find_versions_by_selector(version_selectors)
        end
      end
    end
  end
end
