require 'pact_broker/db'

RSpec.describe "the Pact Broker migrations" do
  it "doesn't have any migrations with the same number" do
    duplicates = Dir.glob(PactBroker::DB::MIGRATIONS_DIR + "/*")
      .collect { |path| path.split("/").last }
      .select  { | filename| filename =~ /^\d\d\d\d/ }
      .group_by{ | filename | filename.split("_").first.to_i }
      .select  { | number, filenames | filenames.size > 1 }
    expect(duplicates).to eq({})
  end
end
