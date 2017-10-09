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

        def resource_exists?
          true
        end

        def to_json
          versions = version_service.find_versions_by_selector(version_selectors)
          criteria = versions.each_with_object({}) { | version, hash | hash[version.pacticipant.name] = version.number }
          lines = matrix_service.find_compatible_pacticipant_versions(criteria)
          PactBroker::Api::Decorators::MatrixPactDecorator.new(lines).to_json(user_options: { base_url: base_url })
        end

        def selectors
          @selectors ||= CGI.parse(request.uri.query)['selector[]']
        end

        def version_selectors
          @version_selectors ||= selectors.select{ | selector| selector.include?("/version/") }
        end

        def pacticipant_selectors
          @pacticipant_selectors ||= selectors.select{ | selector | selectors.include?("/version/")}
        end

      end
    end
  end
end