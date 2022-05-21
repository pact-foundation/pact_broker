require "pact_broker/api/resources/provider_pacts_for_verification"

module PactBroker
  module Api
    module Resources
      describe ProviderPactsForVerification do
        before do
          allow(PactBroker::Pacts::Service).to receive(:find_for_verification).and_return(pacts)
          allow(PactBroker::Api::Decorators::VerifiablePactsDecorator).to receive(:new).and_return(decorator)
          allow_any_instance_of(ProviderPactsForVerification).to receive(:resource_exists?).and_return(provider)
        end

        let(:provider) { double("provider") }
        let(:pacts) { [] }
        let(:path) { "/pacts/provider/Bar/for-verification" }
        let(:decorator) { instance_double("PactBroker::Api::Decorators::VerifiablePactsDecorator") }
        let(:query) do
          {
            provider_version_branch: "main",
            provider_version_tags: ["master"],
            consumer_version_selectors: [ { tag: "dev", latest: "true" }],
            include_pending_status: "true",
            include_wip_pacts_since: "2018-01-01"
          }
        end

        subject { get(path, query) }

        describe "GET" do
          it "finds the pacts for verification by the provider" do
            # Naughty not mocking out the query parsing...
            expect(PactBroker::Pacts::Service).to receive(:find_for_verification).with(
              "Bar",
              "main",
              ["master"],
              PactBroker::Pacts::Selectors.new([PactBroker::Pacts::Selector.latest_for_tag("dev")]),
              {
                include_wip_pacts_since: DateTime.parse("2018-01-01"),
                include_pending_status: true
              }
            )
            subject
          end

          context "when there are validation errors" do
            let(:query) do
              {
                provider_version_tags: true,
              }
            end

            it "returns the keys with the right case" do
              expect(JSON.parse(subject.body)["errors"]).to have_key("provider_version_tags")
            end
          end
        end

        describe "POST" do
          let(:request_body) do
            {
              providerVersionBranch: "main",
              providerVersionTags: ["master"],
              consumerVersionSelectors: [ { tag: "dev", latest: true }],
              includePendingStatus: true,
              includeWipPactsSince: "2018-01-01",
            }
          end

          let(:request_headers) do
            {
              "CONTENT_TYPE" => "application/json",
              "HTTP_ACCEPT" => "application/hal+json"
            }
          end

          subject { post(path, request_body.to_json, request_headers) }

          it "finds the pacts for verification by the provider" do
            # Naughty not mocking out the query parsing...
            expect(PactBroker::Pacts::Service).to receive(:find_for_verification).with(
              "Bar",
              "main",
              ["master"],
              PactBroker::Pacts::Selectors.new([PactBroker::Pacts::Selector.latest_for_tag("dev")]),
              {
                include_wip_pacts_since: DateTime.parse("2018-01-01"),
                include_pending_status: true
              }
            )
            subject
          end

          context "when there are validation errors" do
            let(:request_body) do
              {
                providerVersionTags: true
              }
            end

            it "returns the keys with the right case" do
              expect(JSON.parse(subject.body)["errors"]).to have_key("providerVersionTags")
            end
          end

          context "with the wrong content type" do
            let(:request_headers) do
              {
                "CONTENT_TYPE" => "text/plain",
                "HTTP_ACCEPT" => "application/hal+json"
              }
            end

            let(:request_body) do
              "foo bar"
            end

            subject { post(path, request_body, request_headers) }

            its(:status) { is_expected.to eq 415 }
          end
        end

        it "uses the correct options for the decorator" do
          expect(decorator).to receive(:to_json) do | options |
            expect(options[:user_options][:title]).to eq "Pacts to be verified by provider Bar"
            expect(options[:user_options][:include_pending_status]).to eq true
          end
          subject
        end
      end
    end
  end
end
