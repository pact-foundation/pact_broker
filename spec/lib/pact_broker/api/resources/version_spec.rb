require "pact_broker/api/resources/version"

module PactBroker
  module Api
    module Resources
      describe Version do
        let(:path) { "/pacticipants/Foo/versions/1" }

        context "with an empty body" do
          subject { put(path, nil, "CONTENT_TYPE" => "application/json") }

          its(:status) { is_expected.to eq 201 }
        end

        context "with invalid JSON" do
          subject { put(path, { some: "yaml" }.to_yaml, "CONTENT_TYPE" => "application/json") }

          its(:status) { is_expected.to eq 400 }
        end
      end
    end
  end
end
