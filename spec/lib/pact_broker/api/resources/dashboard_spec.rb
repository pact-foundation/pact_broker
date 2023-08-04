require "pact_broker/api/resources/dashboard"

module PactBroker
  module Api
    module Resources
      describe Dashboard do
        before do
          td.create_pact_with_verification("Foo1", "1", "Bar", "2")
            .create_pact_with_verification("Foo2", "1", "Bar", "2")
            .create_pact_with_verification("Foo3", "1", "Bar", "2")
            .create_pact_with_verification("Foo4", "1", "Bar", "2")
        end

        let(:response_body_hash) { JSON.parse(subject.body) }

        let(:path) { "/dashboard" }

        subject { get(path) }

        it { is_expected.to be_a_hal_json_success_response }

        it "returns a list of items" do
          expect(response_body_hash["items"]).to be_a(Array)
        end

        context "with pagination" do
          subject { get(path, { pageNumber: 1, pageSize: 1 }) }

          it "only returns the items for the page" do
            expect(response_body_hash["items"].size).to eq 1
          end
        end

        context "with invalid pagination" do
          subject { get(path, { pageNumber: -1, pageSize: -1 }) }

          it_behaves_like "an invalid pagination params response"
        end
      end
    end
  end
end
