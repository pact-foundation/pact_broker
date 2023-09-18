OAS_COVERAGE_CHECK_ENABLED = ENV["OAS_COVERAGE_CHECK_ENABLED"] == "true"

# fairly crappy OAS coverage check
if OAS_COVERAGE_CHECK_ENABLED
  require "openapi_first"
  require "openapi_first/coverage"
  require "support/openapi_first/pact_broker_coverage"

  endpoints_to_be_called = OpenapiFirst::PactBrokerCoverage.build_endpoints_list(OpenapiFirst.load("pact_broker_oas.yaml"))

  RSpec.configure do | config |
    config.after(:all) do
      if endpoints_to_be_called.any?
        raise "Missing coverage of #{endpoints_to_be_called.join("\n")}"
      end
    end
  end
end


RSpec.shared_context "app" do
  let(:app) do | example |
    require "openapi_first"
    require "pact_broker/api"
    require "pact_broker/application_context"
    require "rack/pact_broker/application_context"
    application_context = PactBroker::ApplicationContext.default_application_context
    builder = Rack::Builder.new

    # If the feature spec should be used to validate the OAS, add the metadata `validate_oas: true` to the top level spec
    if example.metadata[:validate_oas]
      # To test the validation responses, a deliberately invalid request must be sent.
      # To stop the middleware raising that as an error,
      # add the metadata `skip_oas_request_validation: true` to the individual spec.
      unless example.metadata[:skip_oas_request_validation]
        builder.use OpenapiFirst::RequestValidation, spec: "pact_broker_oas.yaml", raise_error: true
      end

      builder.use OpenapiFirst::ResponseValidation, spec: "pact_broker_oas.yaml", raise_error: true
    end

    if OAS_COVERAGE_CHECK_ENABLED
      builder.use OpenapiFirst::PactBrokerCoverage, endpoints_to_be_called
    end

    builder.use(Rack::PactBroker::ApplicationContext, application_context)
    builder.run(PactBroker.build_api(application_context))
    builder.to_app
  end
end
