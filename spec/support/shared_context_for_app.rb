RSpec.shared_context "app" do
  let(:app) do | example |
    require "pact_broker/api"
    require "pact_broker/application_context"
    require "rack/pact_broker/application_context"
    application_context = PactBroker::ApplicationContext.default_application_context
    builder = Rack::Builder.new

    builder.use(PactBroker::Middleware::MockPuma)
    builder.use(Rack::PactBroker::ApplicationContext, application_context)
    builder.run(PactBroker.build_api(application_context))

    # If the feature spec should be used to validate the OAS, add the metadata `validate_oas: true` to the top level spec
    if example.metadata[:validate_oas]
      OpenapiFirst::Test.app(builder.to_app)
    else
      builder.to_app
    end
  end
end
