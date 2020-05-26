describe "Deleting an integration" do

  let(:path) { "/integrations/provider/Bar/consumer/Foo" }

  subject { delete(path)  }

  context "when the integration exists" do
    before do
      TestDataBuilder.new
        .create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
    end

    it "deletes the resource associated with the integration" do
      expect{ subject }.to change{ PactBroker::Pacts::PactPublication.count }.by(-1)
    end

    it "returns a 204" do
      expect(subject.status).to be 204
    end
  end

  context "when the integration does not exist" do
    it "returns a 404 Not Found" do
      expect(subject.status).to be 404
    end
  end
end
