RSpec.describe "can i deploy" do
  before do
    td.publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "1.2.3", tags: ["dev"], branch: "main")
      .create_environment("prod")
  end

  let(:query) do
    {
      pacticipant: "Foo",
      version: "1.2.3",
      to: "prod"
    }
  end

  let(:response_body) { JSON.parse(subject.body, symbolize_names: true) }
  let(:accept_content_type) { "application/hal+json" }

  subject { get("/can-i-deploy", query, { "HTTP_ACCEPT" => accept_content_type }) }

  it "returns the matrix response" do
    expect(subject).to be_a_hal_json_success_response
    expect(response_body[:matrix]).to be_instance_of(Array)
  end

  context "with an environment" do
    before do
      td.create_environment("test")
    end

    let(:query) do
      {
        pacticipant: "Foo",
        version: "1.2.3",
        environment: "test"
      }
    end

    it "returns the matrix response" do
      expect(subject).to be_a_hal_json_success_response
      expect(response_body[:matrix]).to be_instance_of(Array)
    end
  end

  context "with text/plain" do
    let(:accept_content_type) { "text/plain" }

    it "return text output" do
      expect(subject.headers["Content-Type"]).to include "text/plain"
      expect(subject.body).to include "CONSUMER |"
    end
  end

  context "using the URL format for tags" do
    subject { get("/pacticipants/Foo/latest-version/dev/can-i-deploy/to/prod", nil, { "HTTP_ACCEPT" => "application/hal+json"}) }

    it "returns the matrix response" do
      expect(subject).to be_a_hal_json_success_response
      expect(response_body[:matrix]).to be_instance_of(Array)
    end

    context "the badge" do
      subject { get("/pacticipants/Foo/latest-version/dev/can-i-deploy/to/prod/badge") }

      it "returns a redirect URL" do
        expect(subject.status).to eq 307
        expect(subject.headers["Location"]).to start_with("https://img.shields.io/badge/")
        expect(subject.headers["Location"]).to match(/dev/)
        expect(subject.headers["Location"]).to match(/prod/)
      end
    end
  end

  context "using the URL format for branch/environment" do
    subject { get("/pacticipants/Foo/branches/main/latest-version/can-i-deploy/to-environment/prod", nil, { "HTTP_ACCEPT" => "application/hal+json"}) }

    it "returns the matrix response" do
      expect(subject).to be_a_hal_json_success_response
      expect(response_body[:matrix]).to be_instance_of(Array)
    end

    context "the badge" do
      subject { get("/pacticipants/Foo/branches/main/latest-version/can-i-deploy/to-environment/prod/badge") }

      it "returns a redirect URL" do
        expect(subject.status).to eq 307
        expect(subject.headers["Location"]).to start_with("https://img.shields.io/badge/")
        expect(subject.headers["Location"]).to match(/main/)
        expect(subject.headers["Location"]).to match(/prod/)
      end
    end
  end

  context "with a validation error" do
    let(:query) { {} }

    it "returns an error response" do
      expect(subject.status).to eq 400
      expect(response_body[:errors]).to be_instance_of(Hash)
    end
  end
end
