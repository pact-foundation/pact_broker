require "pact_broker/api/resources/provider_pacts"

module PactBroker
  module Api
    module Resources
      describe ProviderPacts do
        before do
          allow(PactBroker::Pacts::Service).to receive(:find_latest_pact_versions_for_provider).and_return(pacts)
          allow(PactBroker::Api::Decorators::ProviderPactsDecorator).to receive(:new).and_return(decorator)
          allow(PactBroker::Pacticipants::Service).to receive(:find_pacticipant_by_name).and_return(provider)
        end

        let(:provider) { double("provider") }
        let(:pacts) { double("pacts") }
        let(:decorator) { instance_double("PactBroker::Api::Decorators::ProviderPactsDecorator", to_json: json) }
        let(:json) { {some: "json"}.to_json }
        let(:path) { "/pacts/provider/Bar" }

        subject { get path; last_response }

        it "finds the pacticipant" do
          expect(PactBroker::Pacticipants::Service).to receive(:find_pacticipant_by_name).with("Bar")
          subject
        end

        it "returns a 200 response status" do
          expect(subject.status).to eq 200
        end

        it "returns a json response" do
          expect(subject.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
          expect(subject.body).to eq json
        end

        context "with no tag" do
          it "finds all the pacts for the given provider" do
            expect(PactBroker::Pacts::Service).to receive(:find_pact_versions_for_provider).with("Bar", tag: nil)
            subject
          end

          it "sets the correct resource title" do
            expect(decorator).to receive(:to_json) do | options |
              expect(options[:user_options][:title]).to eq "All pact versions for the provider Bar"
            end
            subject
          end
        end

        context "with a tag" do
          let(:path) { "/pacts/provider/Bar/tag/prod" }

          it "finds all the pacts with the given tag for the provider" do
            expect(PactBroker::Pacts::Service).to receive(:find_pact_versions_for_provider).with("Bar", tag: "prod")
            subject
          end

          it "sets the correct resource title" do
            expect(decorator).to receive(:to_json) do | options |
              expect(options[:user_options][:title]).to eq "All pact versions for the provider Bar with consumer version tag 'prod'"
            end
            subject
          end
        end

        context "with the pacticipant does not exist" do
          let(:provider) { nil }

          it "returns a 404" do
            expect(subject.status).to eq 404
          end
        end
      end
    end
  end
end
