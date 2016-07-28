describe "Merging a pact" do

  let(:pact_content) { load_fixture('a_consumer-a_provider.json') }
  let(:path) { "/pacts/provider/A%20Provider/consumer/A%20Consumer/version/1.2.3" }
  let(:response_body_json) { JSON.parse(subject.body) }

  subject do
    patch path, pact_content, {'CONTENT_TYPE' => 'application/json' }; last_response
  end

  context "when a pact for this consumer version does not exist" do
    it "returns a 201 Created" do
      expect(subject.status).to be 201
    end

    it "returns a json body" do
      expect(subject.headers['Content-Type']).to eq "application/json;charset=utf-8"
    end

    it "returns the pact in the body" do
      expect(response_body_json).to include JSON.parse(pact_content)
    end
  end

  context "when a pact for this consumer version does exist" do
    let(:existing_pact_content) { load_fixture('a_consumer-a_provider-2.json') }
    let(:merged_pact_content) { load_fixture('a_consumer-a_provider-merged.json') }

    before do
      ProviderStateBuilder.new.create_pact_with_hierarchy "A Consumer", "1.2.3", "A Provider", existing_pact_content
    end

    it "returns a 200 Success" do
      expect(subject.status).to be 200
    end

    it "returns an application/json Content-Type" do
      expect(subject.headers['Content-Type']).to eq "application/json;charset=utf-8"
    end

    it "returns the merged pact in the response body" do
      expect(response_body_json).to contain_hash JSON.parse(merged_pact_content)
    end
  end

  context "when there are multiple patches to the same pact" do
    # [ThePletch] Tests that race conditions won't cause patches to be dropped
  end

  context "when the pacticipant names in the path do not match those in the pact" do
    let(:path) { "/pacts/provider/Another%20Provider/consumer/A%20Consumer/version/1.2.3" }

    it "returns a json error response" do
      expect(subject).to be_a_json_error_response "does not match"
    end
  end
end
