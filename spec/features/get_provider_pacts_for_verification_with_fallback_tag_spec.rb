describe "Get provider pacts for verification with a fallback tag" do
  let(:request_body) do
    {
      consumerVersionSelectors: [{ tag: "feat-x", fallbackTag: "master", latest: true }],
      providerVersionBranch: "feat-x",
      includePendingStatus: true
    }
  end
  let(:request_headers) { { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/hal+json" } }
  let(:pacts) { JSON.parse(subject.body, symbolize_names: true)[:_embedded][:pacts] }

  subject { post("/pacts/provider/Bar/for-verification", request_body.to_json, request_headers) }

  before do
    td.create_pact_with_consumer_version_tag("Foo", "1", "master", "Bar")
      .create_pact_with_consumer_version_tag("Foo", "2", "feat-x", "Bar")
      .create_pact_with_consumer_version_tag("Foo2", "3", "master", "Bar")
  end

  def pact_named(consumer_name)
    pacts.find { | pact | pact[:_links][:self][:name].start_with?("Pact between #{consumer_name} ") }
  end

  def notice_texts(pact)
    pact[:verificationProperties][:notices].collect { | notice | notice[:text] }
  end

  it "returns the tag pact for one consumer and the fallback pact for the other" do
    expect(pacts.collect { | pact | pact[:_links][:self][:name] }).to contain_exactly(
      a_string_starting_with("Pact between Foo (2)"),
      a_string_starting_with("Pact between Foo2 (3)")
    )
  end

  it "says the tag pact was selected for its tag" do
    expect(notice_texts(pact_named("Foo"))).to include(a_string_including("latest version tagged 'feat-x'"))
    expect(notice_texts(pact_named("Foo")).join).to_not include("fallback")
  end

  it "says the fallback pact was selected by the fallback tag" do
    expect(notice_texts(pact_named("Foo2"))).to include(
      a_string_including("latest version tagged 'master' (fallback tag used as no pact was found with tag 'feat-x')")
    )
  end

  it "marks the fallback pact as pending" do
    expect(pact_named("Foo2")[:verificationProperties][:pending]).to be true
  end
end
