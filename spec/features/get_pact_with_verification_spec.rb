describe "retrieving a pact" do

  let(:path) { "/pacts/provider/Provider/consumer/Consumer/version/1?verification=1" }
  subject { get(path, nil, "HTTP_ACCEPT" => "application/vnd.pactbrokerextended.v1+json")  }

  let(:pact_content) do
    {
      "interactions" => [{
        "_id" => "1"
      }]
    }.to_json
  end

  let(:test_results) do
    {
      "interactionId" => "",
      "success" => false,
      "description" => "asfdsdf",
      "exception" => {
        "message" => "foo",
        "exceptionClass" => "java.io.IOException"
      },
      "mismatches" => [{
        "description" => "Something didn't match",
        "attribute" => "body",
        "identifier" => "$.thing"
        }
      ]
    }
  end

  before do
    td.create_pact_with_hierarchy("Consumer", "1", "Provider", pact_content)
      .create_verification(test_results: test_results)
  end

  it "returns a 200 Success" do
    expect(subject.status).to be 200
  end

  it "returns the test results included in the pact content" do
    expect(JSON.parse(subject.body)["contract"]["interactions"].first["testResults"]).to_not be nil
  end
end
