require "pact_broker/api/resources/error_handling_methods"

module PactBroker
  module Api
    module Resources
      describe ErrorHandlingMethods do
        class TestResource < PactBroker::Api::Resources::BaseResource; end

        describe "#set_json_validation_error_messages" do
          before do
            allow(application_context.decorator_configuration).to receive(:validation_error_decorator_class_for).and_return(decorator_class)
          end
          let(:decorator_class) { double("decorator class", new: decorator) }
          let(:decorator) { double("Decorator", to_json: "body")}
          let(:request) { double("request", env: env, path_info: path_info, headers: headers).as_null_object }
          let(:path_info) { { application_context: application_context } }
          let(:application_context) { PactBroker::ApplicationContext.default_application_context }
          let(:response) { double("response").as_null_object }
          let(:env) { { "pactbroker.base_url" => "http://example.org" } }
          let(:headers) { { "Accept" => "application/hal+json,application/problem+json" } }
          let(:errors) { { "foo" => ["bar"] }  }
          let(:resource) { BaseResource.new(request, response) }

          subject { resource.set_json_validation_error_messages(errors) }

          it "gets the decorator for the errors" do
            expect(application_context.decorator_configuration).to receive(:validation_error_decorator_class_for).with(Hash, "application/hal+json,application/problem+json")
            subject
          end

          it "generates the response body" do
            expect(decorator).to receive(:to_json).with(user_options: { base_url: "http://example.org"})
            subject
          end

          it "sets the response body" do
            expect(response).to receive(:body=).with("body")
            subject
          end
        end
      end
    end
  end
end
