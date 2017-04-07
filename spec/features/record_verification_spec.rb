describe "Recording a pact verification" do

  let(:path) { "/pacts/provider/Provider/consumer/Consumer/versions/1.2.3/verifications" }
  let(:verification_content) { load_fixture('record_verification.json') }
  let(:parsed_response_body) { JSON.parse(subject.body) }

  subject { post path, verification_content, {'CONTENT_TYPE' => 'application/json' }; last_response  }

  before do
    ProviderStateBuilder.new.create_pact_with_hierarchy "Consumer", "1.2.3", "Provider"
  end

  context "" do
    xit "Reponds with a 201 Created" do
      expect(subject.status).to be 201
    end

    xit "saves a verification against the pact" do
    end
  end
end
