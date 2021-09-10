describe "Deleting pact versions for branch" do

  let(:path) { "/pacts/provider/Bar/consumer/Foo/branch/main" }

  subject { delete(path)  }

  context "when the pact exists" do
    before do
      td.create_consumer("Foo")
        .create_provider("Bar")
        .create_consumer_version("1", branch: "main")
        .create_pact
        .create_consumer_version("2", branch: "not-main")
        .create_pact
        .create_consumer("NotFoo")
        .create_consumer_version("1", branch: "main")
        .create_pact
    end

    it "deletes the pacts for the relevant branch" do
      expect{ subject }.to change{ PactBroker::Pacts::PactPublication.count }.by(-1)
    end

    it "returns a 200" do
      expect(subject.status).to be 200
    end
  end

  context "when the pact does not exist" do
    it "returns a 404 Not Found" do
      expect(subject.status).to be 404
    end
  end
end
