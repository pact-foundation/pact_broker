describe "Get provider pacts for verification with a fallback branch" do
  let(:request_body) do
    {
      consumerVersionSelectors: [{ branch: "feat-x", fallbackBranch: "main" }],
      includePendingStatus: false
    }
  end
  let(:request_headers) { { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/hal+json" } }
  let(:pacts) { JSON.parse(subject.body, symbolize_names: true)[:_embedded][:pacts] }

  subject { post("/pacts/provider/Bar/for-verification", request_body.to_json, request_headers) }

  before do
    td.create_consumer("Foo")
      .create_provider("Bar")
      .create_consumer_version("1", branch: "main")
      .create_pact
      .create_consumer_version("2", branch: "feat-x")
      .create_pact
      .create_consumer("Foo2")
      .create_consumer_version("3", branch: "main")
      .create_pact
  end

  def pact_named(consumer_name)
    pacts.find { | pact | pact[:_links][:self][:name].start_with?("Pact between #{consumer_name} ") }
  end

  def notice_texts(pact)
    pact[:verificationProperties][:notices].collect { | notice | notice[:text] }
  end

  it "returns the branch pact for one consumer and the fallback pact for the other" do
    expect(pacts.collect { | pact | pact[:_links][:self][:name] }).to contain_exactly(
      a_string_starting_with("Pact between Foo (2)"),
      a_string_starting_with("Pact between Foo2 (3)")
    )
  end

  it "says the branch pact was selected for its branch" do
    expect(notice_texts(pact_named("Foo"))).to include(a_string_including("latest version from branch 'feat-x'"))
    expect(notice_texts(pact_named("Foo")).join).to_not include("fallback")
  end

  it "says the fallback pact was selected by the fallback branch" do
    expect(notice_texts(pact_named("Foo2"))).to include(
      a_string_including("latest version from branch 'main' (fallback branch used as no pact was found from branch 'feat-x')")
    )
  end
end
