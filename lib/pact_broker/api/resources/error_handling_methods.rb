require "pact_broker/api/decorators/validation_errors_problem_json_decorator"
require "pact_broker/api/decorators/custom_error_problem_json_decorator"

module PactBroker
  module Api
    module Resources
      module ErrorHandlingMethods

        # @override
        def handle_exception(error)
          error_reference = log_and_report_error(error)
          headers, body = application_context.error_response_generator.call(error, error_reference, request.env)
          headers.each { | key, value | response.headers[key] = value }
          response.body = body
        end

        def log_and_report_error(error)
          # generate reference
          error_reference = PactBroker::Errors.generate_error_reference
          # log error
          application_context.error_logger.call(error, error_reference, request.env)
          # report error
          application_context.error_reporter.call(error, error_reference, request.env)
          # generate response
          error_reference
        end

        def set_json_error_message detail, title: "Server error", type: "server_error", status: 500
          response.headers["Content-Type"] = error_response_content_type
          response.body = error_response_body(detail, title, type, status)
        end

        def set_json_validation_error_messages errors
          response.headers["Content-Type"] = error_response_content_type
          if problem_json_error_content_type?
            response.body = PactBroker::Api::Decorators::ValidationErrorsProblemJSONDecorator.new(errors).to_json(**decorator_options)
          else
            response.body = { errors: errors }.to_json
          end
        end

        def error_response_content_type
          if problem_json_error_content_type?
            "application/problem+json;charset=utf-8"
          else
            "application/hal+json;charset=utf-8"
          end
        end

        def error_response_body(detail, title, type, status)
          if problem_json_error_content_type?
            PactBroker::Api::Decorators::CustomErrorProblemJSONDecorator.new(detail: detail, title: title, type: type, status: status).to_json(**decorator_options)
          else
            { error: detail }.to_json
          end
        end

        def problem_json_error_content_type?
          request.headers["Accept"]&.include?("application/problem+json")
        end
      end
    end
  end
end
