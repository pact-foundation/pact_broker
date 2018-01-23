describe 'latest tagged verifications', migration: true do
  before do
    PactBroker::Database.migrate(20180123)
  end

  let(:now) { DateTime.new(2018, 2, 2) }
  let!(:consumer) { create(:pacticipants, {name: 'C', created_at: now, updated_at: now}) }
  let!(:provider) { create(:pacticipants, {name: 'P', created_at: now, updated_at: now}) }
  let!(:consumer_version_1) { create(:versions, {number: '1', order: 1, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }
  let!(:consumer_version_2) { create(:versions, {number: '2', order: 2, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }

  let!(:provider_version_1) { create(:versions, {number: '1', order: 1, pacticipant_id: provider[:id], created_at: now, updated_at: now}) }
  let!(:provider_version_2) { create(:versions, {number: '2', order: 2, pacticipant_id: provider[:id], created_at: now, updated_at: now}) }
  let!(:provider_version_3) { create(:versions, {number: '3', order: 3, pacticipant_id: provider[:id], created_at: now, updated_at: now}) }

  let!(:provider_version_1_prod_tag) { create(:tags, {version_id: provider_version_1[:id], name: 'prod', created_at: now, updated_at: now}, nil) }
  let!(:provider_version_1_dev_tag) { create(:tags, {version_id: provider_version_1[:id], name: 'dev', created_at: now, updated_at: now}, nil) }
  let!(:provider_version_2_dev_tag) { create(:tags, {version_id: provider_version_2[:id], name: 'dev', created_at: now, updated_at: now}, nil) }

  let!(:pact_version_1) { create(:pact_versions, {content: {some: 'json'}.to_json, sha: '1', consumer_id: consumer[:id], provider_id: provider[:id], created_at: now}) }
  let!(:pact_version_2) { create(:pact_versions, {content: {some: 'json other'}.to_json, sha: '2', consumer_id: consumer[:id], provider_id: provider[:id], created_at: now}) }
  #let!(:pact_version_3) { create(:pact_versions, {content: {some: 'json more'}.to_json, sha: '3', consumer_id: consumer[:id], provider_id: provider[:id], created_at: now}) }
  let!(:pact_publication_1) do
    create(:pact_publications, {
      consumer_version_id: consumer_version_1[:id],
      provider_id: provider[:id],
      revision_number: 1,
      pact_version_id: pact_version_1[:id],
      created_at: now
    })
  end

  let!(:pact_publication_2) do
    create(:pact_publications, {
      consumer_version_id: consumer_version_2[:id],
      provider_id: provider[:id],
      revision_number: 1,
      pact_version_id: pact_version_2[:id],
      created_at: now
    })
  end

  # provider v1
  let!(:verification_1) do
    create(:verifications, {
      number: 1,
      success: true,
      provider_version_id: provider_version_1[:id],
      pact_version_id: pact_version_1[:id],
      execution_date: now,
      created_at: now
    })
  end

  # provider v2
  let!(:verification_2) do
    create(:verifications, {
      number: 2,
      success: true,
      provider_version_id: provider_version_2[:id],
      pact_version_id: pact_version_1[:id],
      execution_date: now,
      created_at: now
    })
  end

  # provider v2
  let!(:verification_3) do
    create(:verifications, {
      number: 3,
      success: true,
      provider_version_id: provider_version_2[:id],
      pact_version_id: pact_version_1[:id],
      execution_date: now,
      created_at: now
    })
  end

  it "includes the tag rows for which the related verification is the latest of that tag" do
    rows = database[:latest_verification_tags].all
    expect(rows).to contain_hash(verification_id: verification_1[:id], name: 'prod')
    expect(rows).to contain_hash(verification_id: verification_3[:id], name: 'dev')
    expect(rows.size).to eq 2
  end
end
