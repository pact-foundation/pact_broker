require "pact_broker/api/resources/can_i_deploy"

module PactBroker
  module Api
    module Resources
      describe CanIDeploy do
        include_context "stubbed services"

        before do
          allow(pacticipant_service).to receive(:find_pacticipant_by_name).and_return(pacticipant)
          allow(matrix_service).to receive(:can_i_deploy).and_return(results)
          allow_any_instance_of(described_class).to receive(:matrix_service).and_return(matrix_service)
          allow(PactBroker::Api::Decorators::MatrixDecorator).to receive(:new).and_return(decorator)
        end

        let(:results) { double("results", deployable?: deployable) }
        let(:deployable) { true }
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
        let(:accept) { "application/hal+json" }

        subject { get("/can-i-deploy", query, { "HTTP_ACCEPT" => accept }) }

        context "with the wrong query" do
          let(:query) { {} }

          it "returns a 400" do
            expect(subject.status).to eq 400
            expect(JSON.parse(subject.body)["errors"]["pacticipant"].first).to_not be_empty
          end
        end

        context "when the pacticipant does not exist" do
          let(:pacticipant) { nil }

          it "returns a 400" do
            expect(subject.status).to eq 400
            expect(JSON.parse(subject.body)["errors"]["pacticipant"].first).to match(/Foo.*found/)
          end
        end

        context "when Accept is text/plain" do
          before do
            allow(PactBroker::Api::Decorators::MatrixTextDecorator).to receive(:new).and_return(text_decorator)
          end

          let(:text_decorator) { instance_double("PactBroker::Api::Decorators::MatrixTextDecorator", to_text: "response_body") }
          let(:accept) { "text/plain" }

          it "returns text" do
            expect(subject.headers["Content-Type"]).to include "text/plain"
          end

          context "when the version is deployable" do
            its(:status) { is_expected.to eq 200 }
          end

          context "when the version is not deployable" do
            let(:deployable) { false }

            its(:status) { is_expected.to eq 400 }
          end
        end
      end
    end
  end
end
