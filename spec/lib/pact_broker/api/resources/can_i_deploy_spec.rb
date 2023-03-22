require "pact_broker/api/resources/can_i_deploy"

module PactBroker
  module Api
    module Resources
      describe CanIDeploy do
        include_context "stubbed services"

        before do
          allow(matrix_service).to receive(:can_i_deploy).and_return(results)
          allow_any_instance_of(described_class).to receive(:matrix_service).and_return(matrix_service)
          allow(PactBroker::Api::Decorators::MatrixDecorator).to receive(:new).and_return(decorator)
        end

        let(:results) { double("results") }
        let(:pacticipant) { double("pacticipant") }
        let(:decorator) { instance_double("PactBroker::Api::Decorators::MatrixDecorator", to_json: "response_body") }
        let(:matrix_service) { class_double("PactBroker::Matrix::Service").as_stubbed_const }

        let(:query) do
          {
            pacticipant: "Foo",
            version: "1.2.3",
            to: "prod"
          }
        end

        subject { get("/can-i-deploy", query, { "HTTP_ACCEPT" => "application/hal+json"}) }

        context "with the wrong query" do
          let(:query) { {} }

          it "returns a 400" do
            expect(subject.status).to eq 400
            expect(JSON.parse(subject.body)["errors"]["pacticipant"].first).to_not be_empty
          end
        end
      end
    end
  end
end
