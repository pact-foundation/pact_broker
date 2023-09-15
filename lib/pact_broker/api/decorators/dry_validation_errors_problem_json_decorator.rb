require "pact_broker/api/decorators/base_decorator"
require "pact_broker/api/decorators/embedded_error_problem_json_decorator"
# Formats a Dry::Validation::MessageSet into application/problem+json format.
# according to the spec at https://www.rfc-editor.org/rfc/rfc9457.html

# Decorates Dry::Validation::MessageSet
# Defaults to displaying validation errors, but the top level
# details may be overridden to display error responses for other HTTP statuses (eg. 409)
module PactBroker
  module Api
    module Decorators
      class DryValidationErrorsProblemJsonDecorator < BaseDecorator

        property :title,    getter: -> (user_options:, **) { user_options[:title]    || "Validation errors" }
        property :type,     getter: -> (user_options:, **) { user_options[:type]     || "#{user_options[:base_url]}/problems/validation-error" }
        property :detail,   getter: -> (user_options:, **) { user_options[:detail]   || nil }
        property :status,   getter: -> (user_options:, **) { user_options[:status]   || 400 }
        property :instance, getter: -> (user_options:, **) { user_options[:instance] || "/" }

        collection :entries, as: :errors, extend: PactBroker::Api::Decorators::EmbeddedErrorProblemJsonDecorator
      end
    end
  end
end
