require 'pact/mock_service/request_handlers/base_administration_request_handler'

module Pact
  module MockService
    module RequestHandlers
      class VerificationGet < BaseAdministrationRequestHandler

        def initialize name, logger, session
          super name, logger
          @expected_interactions = session.expected_interactions
          @actual_interactions = session.actual_interactions
        end

        def request_path
          '/interactions/verification'
        end

        def request_method
          'GET'
        end

        def respond env
          verification = Pact::MockService::Interactions::Verification.new(expected_interactions, actual_interactions)
          example_desc = example_description(env)
          example_desc = example_desc ? " for example #{example_desc.inspect}" : ''
          if verification.all_matched?
            logger.info "Verifying - interactions matched#{example_desc}"
            text_response('Interactions matched')
          else
            error_message = FailureMessage.new(verification).to_s
            logger.warn "Verifying - actual interactions do not match expected interactions#{example_desc}. \n#{error_message}"
            logger.warn error_message
            response_message = "Actual interactions do not match expected interactions for mock #{name}.\n\n#{error_message}See #{logger.description} for details."
            text_response(response_message, 500)
          end
        end

        private

        attr_accessor :expected_interactions, :actual_interactions

        def example_description env
          params_hash(env).fetch("example_description", [])[0]
        end

        class FailureMessage

          def initialize verification
            @verification = verification
          end

          def to_s
            titles_and_summaries.collect do | title, summaries |
              "#{title}:\n\t#{summaries.join("\n\t")}\n\n" if summaries.any?
            end.compact.join + verification.interaction_mismatches.collect(&:to_s).join("\n\n") + "\n"

          end

          private

          attr_reader :verification

          def titles_and_summaries
            {
              "Incorrect requests" => verification.interaction_mismatches_summaries,
              "Missing requests" => verification.missing_interactions_summaries,
              "Unexpected requests" => verification.unexpected_requests_summaries,
            }
          end
        end
      end
    end
  end
end
