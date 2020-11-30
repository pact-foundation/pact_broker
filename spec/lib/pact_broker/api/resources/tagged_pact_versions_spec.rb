require 'pact_broker/api/resources/tagged_pact_versions'

module PactBroker
  module Api
    module Resources
      describe TaggedPactVersions do
        include_context "stubbed services"

        before do
          allow(pacticipant_service).to receive(:find_pacticipant_by_name).with("Foo").and_return(consumer)
          allow(pacticipant_service).to receive(:find_pacticipant_by_name).with("Bar").and_return(provider)
        end

        let(:path) { "/pacts/provider/Bar/consumer/Foo/tag/prod" }
        let(:consumer) { double('Bar') }
        let(:provider) { double('Foo') }

        context "GET" do
          before do
            allow(PactBroker::Api::Decorators::TaggedPactVersionsDecorator).to receive(:new).and_return(decorator)
            allow(pact_service).to receive(:find_all_pact_versions_between).and_return(pact_versions)
          end

          let(:decorator) { instance_double(PactBroker::Api::Decorators::TaggedPactVersionsDecorator, to_json: 'json') }
          let(:pact_versions) { double('pacts') }

          subject { get(path) }

          let(:user_options) do
            register_fixture(:tagged_pact_versions_decorator_user_options) do
              {
                base_url: "http://example.org",
                resource_url: "http://example.org/pacts/provider/Bar/consumer/Foo/tag/prod",
                consumer_name: "Foo",
                provider_name: "Bar",
                tag: "prod"
              }
            end
          end

          it "finds all the pacts with the given consumer/provider/tag" do
            expect(pact_service).to receive(:find_all_pact_versions_between).with("Foo", and: "Bar", tag: "prod")
            subject
          end

          it "returns a 200 OK hal+json response" do
            expect(subject).to be_a_hal_json_success_response
          end

          it "creates a JSON representation of the pact versions" do
            expect(PactBroker::Api::Decorators::TaggedPactVersionsDecorator).to receive(:new).with(pact_versions)
            expect(decorator).to receive(:to_json).with(user_options: hash_including(user_options))
            subject
          end

          it "returns the JSON representation of the pact versions" do
            expect(subject.body).to eq 'json'
          end

          context "with the consumer or provider do not exist" do
            let(:consumer) { nil }

            it "returns a 404" do
              expect(subject).to be_a_404_response
            end
          end
        end

        context "DELETE" do
          before do
            allow(pact_service).to receive(:delete_all_pact_publications_between)
            allow(pact_service).to receive(:find_latest_pact).and_return(latest_pact)
            allow_any_instance_of(described_class).to receive(:latest_pact_url).and_return("http://latest-pact")
          end

          let(:latest_pact) { double('pact') }

          subject { delete(path) }

          it "deletes all the pacts with the given consumer/provider/tag" do
            expect(pact_service).to receive(:delete_all_pact_publications_between).with("Foo", and: "Bar", tag: "prod")
            subject
          end

          it "returns a 200" do
            expect(subject.status).to eq 200
          end

          it "returns a link to the latest pact" do
            expect(JSON.parse(subject.body)["_links"]["pb:latest-pact-version"]["href"]).to eq "http://latest-pact"
          end
        end
      end
    end
  end
end
