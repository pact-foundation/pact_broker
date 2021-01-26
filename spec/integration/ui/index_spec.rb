require 'pact_broker/ui/app'

describe "UI index" do

  let(:app) { PactBroker::UI::App.new }
  let(:td) { TestDataBuilder.new }
  let(:params) { {} }

  before do
    td.create_pact_with_hierarchy("Foo", "1", "Bar")
      .create_consumer_version_tag("prod")
      .create_consumer_version("2")
      .create_pact
    get "/"
  end

  let(:rack_env) { {} }

  subject { get("/", params, rack_env) }

  describe "GET" do
    it "returns a success response" do
      expect(subject.status).to eq 200
    end

    it "returns a table of pacts" do
      expect(subject.body.scan('<tr').to_a.count).to eq 2
    end

    context "with an array of tags" do
      let(:params) { { tags: ['prod'] } }

      it "returns a table of pacts with the specfied tags" do
        expect(subject.body.scan('<tr').to_a.count).to eq 3
      end
    end

    context "with the base_url not set" do
      it "returns relative links" do
        expect(subject.body).to include "href='/stylesheets"
      end
    end

    context "with the base_url set" do
      let(:rack_env) { { "pactbroker.base_url" => "http://example.org/pact-broker"} }

      it "returns absolute links" do
        expect(subject.body).to include "href='http://example.org/pact-broker/stylesheets"
      end
    end
  end
end
