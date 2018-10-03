describe "Deleting tagged pact versions" do

  let(:path) { "/pacts/provider/Bar/consumer/Foo/tag/prod" }

  subject { delete(path)  }

  context "when the pact exists" do
    before do
      TestDataBuilder.new
        .create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
        .create_consumer_version_tag("prod")
    end

    it "deletes the pact" do
      expect{ subject }.to change{ PactBroker::Pacts::PactPublication.count }.by(-1)
    end

    it "returns a 204" do
      expect(subject.status).to be 204
    end
  end

  context "when the pact does not exist" do
    it "returns a 404 Not Found" do
      expect(subject.status).to be 404
    end
  end
end
