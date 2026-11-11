require "spec/support/test_data_builder"

describe "Get matrix for consumer and provider" do
  before do
    td.create_pact_with_hierarchy("Consumer", "1.0.0", "Provider")
      .create_verification(provider_version: "4.5.6")
  end

  let(:path) { "/matrix" }
  let(:params) do
    {
      q: [
        { pacticipant: "Consumer", version: "1.0.0" },
        { pacticipant: "Provider", version: "4.5.6" }
      ]
    }
  end
  let(:rack_env) { {} }
  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get(path, params, rack_env) }

  it "returns a 200 HAL JSON response" do
    expect(subject).to be_a_hal_json_success_response
  end

  it "returns the JSON representation of the matrix" do
    expect(last_response_body[:matrix][0][:consumer]).to be_instance_of(Hash)
    expect(last_response_body[:matrix][0][:provider]).to be_instance_of(Hash)
    expect(last_response_body[:matrix][0][:pact]).to be_instance_of(Hash)
    expect(last_response_body[:matrix][0][:verificationResult]).to be_instance_of(Hash)
  end

  context "with Accept: text/plain" do
    let(:rack_env) { { "HTTP_ACCEPT" => "text/plain" } }

    its(:headers) { is_expected.to include("Content-Type" => "text/plain;charset=utf-8") }
  end

  context "when a matrix_max_limit is configured" do
    before do
      allow(PactBroker.configuration).to receive(:matrix_max_limit).and_return(1000)
    end

    context "when the request has no limit and the maximum is the lowest allowed" do
      before do
        allow(PactBroker.configuration).to receive(:matrix_max_limit).and_return(100)
      end

      it "returns a 200 HAL JSON response, because the default limit is within the maximum" do
        expect(subject).to be_a_hal_json_success_response
      end
    end

    # A maximum below 100 is rejected when the configuration loads. This shows why.
    context "when the request has no limit and the maximum is below the default limit of 100" do
      before do
        allow(PactBroker.configuration).to receive(:matrix_max_limit).and_return(50)
      end

      it "returns a 400 response, because the default limit of 100 exceeds the maximum" do
        expect(subject.status).to eq 400
        expect(subject.body).to include "The limit must be 50 or less."
      end
    end

    context "when the limit is at the maximum" do
      let(:params) { super().merge(limit: "1000") }

      it "returns a 200 HAL JSON response" do
        expect(subject).to be_a_hal_json_success_response
      end
    end

    context "when the limit exceeds the maximum" do
      let(:params) { super().merge(limit: "1001") }

      it "returns a 400 response with an error message" do
        expect(subject.status).to eq 400
        expect(subject.body).to include "The limit must be 1000 or less."
      end
    end
  end
end
