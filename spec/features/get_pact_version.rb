describe "retrieving a pact" do
  subject { get path; last_response  }

  context "when differing case is used in the consumer and provider names" do
    let(:td) { TestDataBuilder.new }
    let(:pact) { td.create_pact_with_hierarchy("Foo", "1", "Bar").and_return(:pact) }
    let!(:path) { "/pacts/provider/Bar/consumer/Foo/pact-version/#{pact.pact_version_sha}" }

    it "returns a 200 Success" do
      expect(subject.status).to be 200
    end
  end
end
