describe 'create latest matrix (latest pact revision/latest verification for provider version)', migration: true do
  before do
    PactBroker::Database.migrate(50)
  end

  def shorten_row row
    "#{row[:consumer_name]}#{row[:consumer_version_number]} #{row[:provider_name]}#{row[:provider_version_number] || '?'} (r#{row[:pact_revision_number]}/n#{row[:verification_number] || '?'})"
  end

  let(:now) { DateTime.new(2018, 2, 2) }
  let!(:consumer) { create(:pacticipants, {name: 'C', created_at: now, updated_at: now}) }
  let!(:provider) { create(:pacticipants, {name: 'P', created_at: now, updated_at: now}) }
  let!(:consumer_version_1) { create(:versions, {number: '1', order: 1, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }
  let!(:consumer_version_2) { create(:versions, {number: '2', order: 2, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }
  let!(:provider_version_1) { create(:versions, {number: '1', order: 1, pacticipant_id: provider[:id], created_at: now, updated_at: now}) }
  let!(:provider_version_2) { create(:versions, {number: '2', order: 2, pacticipant_id: provider[:id], created_at: now, updated_at: now}) }
  let!(:pact_version_1) { create(:pact_versions, {content: {some: 'json'}.to_json, sha: '1', consumer_id: consumer[:id], provider_id: provider[:id], created_at: now}) }
  let!(:pact_version_2) { create(:pact_versions, {content: {some: 'json other'}.to_json, sha: '2', consumer_id: consumer[:id], provider_id: provider[:id], created_at: now}) }
  let!(:pact_version_3) { create(:pact_versions, {content: {some: 'json more'}.to_json, sha: '3', consumer_id: consumer[:id], provider_id: provider[:id], created_at: now}) }
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
      consumer_version_id: consumer_version_1[:id],
      provider_id: provider[:id],
      revision_number: 2,
      pact_version_id: pact_version_2[:id],
      created_at: now
    })
  end

  # C2 P? (r1/n?)
  let!(:pact_publication_3) do
    create(:pact_publications, {
      consumer_version_id: consumer_version_2[:id],
      provider_id: provider[:id],
      revision_number: 1,
      pact_version_id: pact_version_3[:id],
      created_at: now
    })
  end

  # C1 P3 (r1n3)
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

  # C1 P3 (r1n1)
  let!(:verification_2) do
    create(:verifications, {
      number: 1,
      success: true,
      provider_version_id: provider_version_1[:id],
      pact_version_id: pact_version_2[:id],
      execution_date: now,
      created_at: now
    })
  end

  # include
  let!(:verification_3) do
    create(:verifications, {
      number: 2,
      success: true,
      provider_version_id: provider_version_1[:id],
      pact_version_id: pact_version_2[:id],
      execution_date: now,
      created_at: now
    })
  end

  # include
  let!(:verification_4) do
    create(:verifications, {
      number: 3,
      success: true,
      provider_version_id: provider_version_2[:id],
      pact_version_id: pact_version_2[:id],
      execution_date: now,
      created_at: now
    })
  end

  # C1 P1 (r1/n1) this pact version is overwritten by r2
  # C1 P1 (r2/n1) this verification is overwritten by n2
  # C1 P1 (r2/n2)
  # C1 P2 (r2/n3)
  # C2 P? (r1/n?)

  it "only includes the latest pact revisions and latest verifications" do
    puts database[:matrix].order(:consumer_version_order, :provider_version_order, :pact_revision_number, :verification_id).all.collect{ |r| shorten_row(r) }
    rows = database[:latest_matrix].order(:verification_id).all.collect{|row| shorten_row(row) }
    expect(rows).to include "C1 P1 (r2/n2)"
    expect(rows).to include "C1 P2 (r2/n3)"
    expect(rows).to include "C2 P? (r1/n?)"
    expect(rows).to_not include "C1 P1 (r2/n1)"
    expect(database[:latest_matrix].count).to eq 3
  end
end
