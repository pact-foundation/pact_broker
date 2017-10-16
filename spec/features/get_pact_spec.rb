describe "retrieving a pact" do

  subject { get path; last_response  }

  context "when differing case is used in the consumer and provider names" do

    let(:path) { "/pacts/provider/a%20provider/consumer/a%20consumer/version/1.2.3A" }

    before do
      TestDataBuilder.new.create_pact_with_hierarchy("A Consumer", "1.2.3a", "A Provider").and_return(:pact)
    end

    context "when case sensitivity is turned on" do
      before do
        allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(true)
      end

      it "returns a 404 Not found" do
        expect(subject.status).to be 404
      end
    end

    context "when case sensitivity is turned off" do
      before do
        allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(false)
      end

      it "returns a 200 Success" do
        expect(subject.status).to be 200
      end
    end
  end
  context "when differing case is used in the tag name" do

    let(:path) { "/pacts/provider/a%20provider/consumer/a%20consumer/latest/PROD" }

    before do
      TestDataBuilder.new
        .create_consumer("A Consumer")
        .create_consumer_version("1.2.3")
        .create_consumer_version_tag("prod")
        .create_provider("A Provider")
        .create_pact
    end

    context "when case sensitivity is turned on" do
      before do
        allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(true)
      end

      it "returns a 404 Not found" do
        expect(subject.status).to be 404
      end
    end

    context "when case sensitivity is turned off" do
      before do
        allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(false)
      end

      it "returns a 200 Success" do
        expect(subject.status).to be 200
      end
    end
  end
end
