describe 'add provider version relationship to verification (migrate 42-44)', migration: true do
  before do
    PactBroker::Database.migrate(42)
  end

  let(:now) { DateTime.new(2018, 2, 2) }
  let!(:consumer) { create(:pacticipants, {name: 'Consumer', created_at: now, updated_at: now}) }
  let!(:provider) { create(:pacticipants, {name: 'Provider', created_at: now, updated_at: now}) }
  let!(:provider) { create(:pacticipants, {name: 'Provider', created_at: now, updated_at: now}) }
  let!(:consumer_version) { create(:versions, {number: '1.2.3', order: 1, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }
  let!(:pact_version) { create(:pact_versions, {content: {some: 'json'}.to_json, sha: '1234', consumer_id: consumer[:id], provider_id: provider[:id], created_at: now}) }
  let!(:pact_publication) do
    create(:pact_publications, {
      consumer_version_id: consumer_version[:id],
      provider_id: provider[:id],
      revision_number: 1,
      pact_version_id: pact_version[:id],
      created_at: (now - 1)
    })
  end
  let!(:verification) do
    create(:verifications, {
      number: 1,
      success: true,
      provider_version: '1.2.3',
      pact_version_id: pact_version[:id],
      execution_date: now,
      created_at: now
    })
  end

  subject { PactBroker::Database.migrate(46) }

  it "creates a version object" do
    expect { subject }.to change { PactBroker::Domain::Version.count }.by(1)
  end

  it "sets the foreign key to the new version" do
    subject
    expect(PactBroker::Domain::Verification.first.provider_version.number).to eq '1.2.3'
  end

  it "sets the created_at date of the new version to the created_at of the verification" do
    subject
    expect(PactBroker::Domain::Verification.first.provider_version.created_at).to eq now
  end

  context "when the version already exists" do
    let!(:provider_version) { create(:versions, {number: '1.2.3', order: 1, pacticipant_id: provider[:id], created_at: now, updated_at: now}) }

    it "does not create a version object" do
      expect { subject }.to_not change { PactBroker::Domain::Version.count }
    end

    it "sets the foreign key to the existing version" do
      subject
      expect(PactBroker::Domain::Verification.first.provider_version.number).to eq '1.2.3'
    end
  end
end
