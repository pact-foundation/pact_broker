describe "Delete pacticipant branches" do
  before do
    td.create_consumer("Bar")
      .create_consumer_version("1", branch: "main")
      .create_consumer("Foo", main_branch: "main")
      .create_consumer_version("1", branch: "main")
      .create_consumer_version("2", branch: "feat/bar")
      .create_consumer_version("3", branch: "feat/foo")
  end
  let(:path) { PactBroker::Api::PactBrokerUrls.pacticipant_branches_url(td.and_return(:pacticipant)) }
  let(:rack_env) do
    {
      "pactbroker.database_connector" => lambda { |&block| block.call }
    }
  end

  subject { delete(path + "?exclude[]=feat%2Fbar", nil, rack_env) }

  its(:status) { is_expected.to eq 202 }

  it "deletes all except the excluded branches for a pacticipant" do
    expect { subject }.to change {
      PactBroker::Versions::Branch
        .where(pacticipant_id: td.and_return(:pacticipant).id)
        .all
        .collect(&:name)
        .sort
    }.from(["feat/bar", "feat/foo", "main"]).to(["feat/bar", "main"])
  end
end
