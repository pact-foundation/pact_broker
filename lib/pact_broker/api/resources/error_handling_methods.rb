require "pact_broker/api/decorators/validation_errors_problem_json_decorator"
require "pact_broker/api/decorators/custom_error_problem_json_decorator"

module PactBroker
  module Api
    module Resources
      module ErrorHandlingMethods

        # @override
        # @param [StandardError] error
        def handle_exception(error)
          error_reference = log_and_report_error(error)
          headers, body = application_context.error_response_generator.call(error, error_reference, request.env)
          headers.each { | key, value | response.headers[key] = value }
          response.body = body
        end

        # @param [StandardError] error
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

        # @param [String] detail
        # @param [String] title
        # @param [String] type
        # @param [Integer] status
        def set_json_error_message(detail, title: "Server error", type: "server-error", status: 500)
          response.headers["Content-Type"] = error_response_content_type
          response.body = error_response_body(detail, title, type, status)
        end

        # @param [Hash,Dry::Validation::MessageSet] errors
        def set_json_validation_error_messages(errors)
          response.headers["Content-Type"] = error_response_content_type
          response.body = validation_errors_response_body(errors)
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
            decorator_class(:custom_error_problem_json_decorator).new(detail: detail, title: title, type: type, status: status).to_json(**decorator_options_for_error)
          else
            decorator_class(:error_decorator).new(detail).to_json
          end
        end

        # @param [Hash,Dry::Validation::MessageSet] errors
        def validation_errors_response_body(errors)
          validation_errors_decorator_class(errors).new(errors).to_json(**decorator_options_for_error)
        end

        # @param [Hash,Dry::Validation::MessageSet] errors
        def validation_errors_decorator_class(errors)
          application_context.decorator_configuration.validation_error_decorator_class_for(errors.class, request.headers["Accept"])
        end

        def problem_json_error_content_type?
          request.headers["Accept"]&.include?("application/problem+json")
        end

        # If we use the normal decorator options that have policy objects we can get into recursive loops in Pactflow, so just make a simple variant of the
        # decorator options here
        def decorator_options_for_error
          { user_options: { base_url: base_url } }
        end
      end
    end
  end
end
