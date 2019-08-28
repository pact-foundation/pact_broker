RSpec.describe "" do
  before do
    td.create_consumer("Foo")
      .create_provider("Bar")
      .create_consumer_version("1")
      .create_pact
      .create_verification(number: 1, provider_version: "2", tag_names: ['staging'])
      .create_verification(number: 2, provider_version: "2")
      .create_verification(number: 3, provider_version: "2")
      .create_verification(number: 4, provider_version: "2")
      .create_verification(number: 5, provider_version: "3")
      .create_provider("Wiffle")
      .create_pact
      .create_verification(number: 1, provider_version: "6", tag_names: ['staging'])
  end

  let(:path) { "/matrix?q[][pacticipant]=Foo&q[][version]=1&tag=staging&latestby=cvp&limit=2" }

  subject { get(path) }

  it "" do
    expect(JSON.parse(subject.body)['summary']['deployable']).to be true
  end
end
