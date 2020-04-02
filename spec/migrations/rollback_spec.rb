describe "migrate and rollback", migration: true do
  it "doesn't blow up" do
    PactBroker::Database.migrate
    PactBroker::Database.migrate(45) # uses an irreversible migration
  end
end
