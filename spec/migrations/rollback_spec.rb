describe "migrate and rollback", migration: true do
  it "doesn't blow up" do
    PactBroker::Database.migrate
    PactBroker::Database.migrate(20190509) # previous migration uses an irreversible migration
  end
end
