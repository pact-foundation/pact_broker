require "pact_broker/api/resources/integrations"

module PactBroker
  module Api
    module Resources
      describe Integrations do
        describe "GET" do
          before do
            allow_any_instance_of(described_class).to receive(:integration_service).and_return(integration_service)
            allow(integration_service).to receive(:find_all).and_return(integrations)
            allow_any_instance_of(described_class).to receive(:decorator_class).and_return(decorator_class)
            allow_any_instance_of(described_class).to receive_message_chain(:decorator_class, :eager_load_associations).and_return(eager_load_associations)
            allow(PactBroker::Api::Contracts::PaginationQueryParamsSchema).to receive(:call).and_return(double("result", errors: errors))
          end

          let(:integration_service) { class_double("PactBroker::Integrations::Service").as_stubbed_const }
          let(:integrations) { double("integrations") }
          let(:decorator_class) { double("decorator class", new: decorator) }
          let(:decorator) { double("decorator", to_json: json) }
          let(:json) { "some json" }
          let(:rack_headers) { { "HTTP_ACCEPT" => "application/hal+json" } }
          let(:eager_load_associations) { [:foo, :bar] }
          let(:errors) { {} }

          let(:path) { "/integrations" }
          let(:params) { { "pageNumber" => "1", "pageSize" => "2" } }

          subject { get(path, params, rack_headers) }

          it "validates the query params" do
            expect(PactBroker::Api::Contracts::PaginationQueryParamsSchema).to receive(:call).with(params)
            subject
          end

          it "finds the integrations" do
            allow(integration_service).to receive(:find_all).with({}, { page_number: 1, page_size: 2 }, eager_load_associations)
            subject
          end

          its(:status) { is_expected.to eq 200 }

          it "renders the integrations" do
            expect(decorator_class).to receive(:new).with(integrations)
            expect(decorator).to receive(:to_json).with(user_options: instance_of(Decorators::DecoratorContext))
            expect(subject.body).to eq json
          end

          context "with invalid query params" do
            let(:errors) { { "some" => ["errors"]} }

            its(:status) { is_expected.to eq 400 }
            its(:body) { is_expected.to match "some.*errors" }
          end
        end
      end
    end
  end
end
