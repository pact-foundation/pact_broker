# frozen_string_literal: true

require_relative 'coverage/plan'

module OpenapiFirst
  module Test
    # The Coverage module is about tracking request and response validation
    # to assess if all parts of the API description have been tested.
    # Currently it does not care about unknown requests that are not part of any API description.
    module Coverage
      autoload :TerminalFormatter, 'openapi_first/test/coverage/terminal_formatter'

      Result = Data.define(:plans, :coverage)

      @current_run = {}

      class << self
        attr_reader :current_run

        def install = Test.install

        def start(skip_response: nil, skip_route: nil)
          @current_run = Test.definitions.values.to_h do |oad|
            plan = Plan.for(oad, skip_response:, skip_route:)
            [oad.key, plan]
          end
        end

        def uninstall = Test.uninstall

        # Clear current coverage run
        def reset
          @current_run = {}
        end

        def track_request(request, oad)
          current_run[oad.key]&.track_request(request)
        end

        def track_response(response, _request, oad)
          current_run[oad.key]&.track_response(response)
        end

        def result
          Result.new(plans:, coverage:)
        end

        # Returns all plans (Plan) that were registered for this run
        def plans
          current_run.values
        end

        private

        def coverage
          return 0 if plans.empty?

          plans.sum(&:coverage) / plans.length
        end
      end
    end
  end
end
