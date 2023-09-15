RSpec.shared_context "app" do
  let(:app) do
    require "pact_broker/api"
    require "pact_broker/application_context"
    require "rack/pact_broker/application_context"
    application_context = PactBroker::ApplicationContext.default_application_context
    builder = Rack::Builder.new
    builder.use(Rack::PactBroker::ApplicationContext, application_context)
    builder.run(PactBroker.build_api(application_context))
    builder.to_app
  end
end
