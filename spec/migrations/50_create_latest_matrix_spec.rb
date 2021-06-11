describe "create latest matrix (latest pact revision/latest verification for provider version)", migration: true do
  before do
    PactBroker::Database.migrate(20180129)
  end

  def shorten_row row
    "#{row[:consumer_name]}#{row[:consumer_version_number]} #{row[:provider_name]}#{row[:provider_version_number] || '?'} (r#{row[:pact_revision_number]}/n#{row[:verification_number] || '?'})"
  end

  let(:now) { DateTime.new(2018, 2, 2) }
  let!(:consumer) { create(:pacticipants, {name: "C", created_at: now, updated_at: now}) }
  let!(:provider_1) { create(:pacticipants, {name: "P", created_at: now, updated_at: now}) }
  let!(:provider_2) { create(:pacticipants, {name: "Q", created_at: now, updated_at: now}) }
  let!(:consumer_version_1) { create(:versions, {number: "1", order: 1, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }
  let!(:consumer_version_2) { create(:versions, {number: "2", order: 2, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }
  let!(:provider_1_version_1) { create(:versions, {number: "1", order: 1, pacticipant_id: provider_1[:id], created_at: now, updated_at: now}) }
  let!(:provider_1_version_2) { create(:versions, {number: "2", order: 2, pacticipant_id: provider_1[:id], created_at: now, updated_at: now}) }
  let!(:provider_2_version_1) { create(:versions, {number: "1", order: 1, pacticipant_id: provider_2[:id], created_at: now, updated_at: now}) }
  let!(:provider_2_version_2) { create(:versions, {number: "2", order: 2, pacticipant_id: provider_2[:id], created_at: now, updated_at: now}) }

  let!(:pact_version_1) { create(:pact_versions, {content: {some: "json"}.to_json, sha: "1", consumer_id: consumer[:id], provider_id: provider_1[:id], created_at: now}) }
  let!(:pact_version_2) { create(:pact_versions, {content: {some: "json other"}.to_json, sha: "2", consumer_id: consumer[:id], provider_id: provider_1[:id], created_at: now}) }
  let!(:pact_version_3) { create(:pact_versions, {content: {some: "json more"}.to_json, sha: "3", consumer_id: consumer[:id], provider_id: provider_1[:id], created_at: now}) }
  let!(:pact_version_4) { create(:pact_versions, {content: {some: "json more blah"}.to_json, sha: "4", consumer_id: consumer[:id], provider_id: provider_2[:id], created_at: now}) }

  let!(:pact_publication_1) do
    create(:pact_publications, {
      consumer_version_id: consumer_version_1[:id],
      provider_id: provider_1[:id],
      revision_number: 1,
      pact_version_id: pact_version_1[:id],
      created_at: now
    })
  end

  let!(:pact_publication_2) do
    create(:pact_publications, {
      consumer_version_id: consumer_version_1[:id],
      provider_id: provider_1[:id],
      revision_number: 2,
      pact_version_id: pact_version_2[:id],
      created_at: now
    })
  end

  # C2 P? (r1/n?)
  let!(:pact_publication_3) do
    create(:pact_publications, {
      consumer_version_id: consumer_version_2[:id],
      provider_id: provider_1[:id],
      revision_number: 1,
      pact_version_id: pact_version_3[:id],
      created_at: now
    })
  end

  # C2 Q1 (r1/n1)
  let!(:pact_publication_4) do
    create(:pact_publications, {
      consumer_version_id: consumer_version_2[:id],
      provider_id: provider_2[:id],
      revision_number: 1,
      pact_version_id: pact_version_4[:id],
      created_at: now
    })
  end

  # C1 P3 (r1n3)
  let!(:verification_1) do
    create(:verifications, {
      number: 1,
      success: true,
      provider_version_id: provider_1_version_1[:id],
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
      provider_version_id: provider_1_version_1[:id],
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
      provider_version_id: provider_1_version_1[:id],
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
      provider_version_id: provider_1_version_2[:id],
      pact_version_id: pact_version_2[:id],
      execution_date: now,
      created_at: now
    })
  end

  # include
  # C1 Q1 (r1/n1)
  let!(:verification_5) do
    create(:verifications, {
      number: 1,
      success: true,
      provider_version_id: provider_2_version_1[:id],
      pact_version_id: pact_version_4[:id],
      execution_date: now,
      created_at: now
    })
  end

  # include
  # C1 Q2 (r1/n2)
  let!(:verification_6) do
    create(:verifications, {
      number: 2,
      success: true,
      provider_version_id: provider_2_version_2[:id],
      pact_version_id: pact_version_4[:id],
      execution_date: now,
      created_at: now
    })
  end

  # C1 P1 (r1/n1) this pact version is overwritten by r2
  # C1 P1 (r2/n1) this verification is overwritten by n2
  # C1 P1 (r2/n2)
  # C1 P2 (r2/n3)
  # C2 P? (r1/n?)

  describe "matrix" do
    it "includes every revision and every verification" do
      rows = database[:matrix].order(:verification_id).all.collect{|row| shorten_row(row) }
      expect(rows).to include "C1 P1 (r1/n1)"
      expect(rows).to include "C1 P1 (r2/n1)"
      expect(rows.count).to eq 7
    end
  end

  it "only includes the latest pact revisions and latest verifications" do
    rows = database[:latest_matrix_for_consumer_version_and_provider_version].order(:verification_id).all.collect{|row| shorten_row(row) }
    expect(rows).to include "C1 P1 (r2/n2)"
    expect(rows).to include "C1 P2 (r2/n3)"
    expect(rows).to include "C2 P? (r1/n?)"
    expect(rows).to include "C2 Q1 (r1/n1)"
    expect(rows).to include "C2 Q2 (r1/n2)"
    expect(rows).to_not include "C1 P1 (r1/n1)"
    expect(rows).to_not include "C1 P1 (r2/n1)"
    expect(database[:latest_matrix_for_consumer_version_and_provider_version].count).to eq 5
  end

  describe "latest matrix" do
    it "only includes the latest pact revisions and latest verifications for the latest consumer versions" do
      rows = database[:latest_matrix].order(:verification_id).all.collect{|row| shorten_row(row) }
      expect(rows).to include "C2 P? (r1/n?)"
      expect(rows).to include "C2 Q2 (r1/n2)"
      expect(rows).to_not include "C2 Q1 (r1/n1)" # not latest provider version
      expect(rows).to_not include "C1 P1 (r2/n2)" # not latest consumer version
      expect(rows).to_not include "C1 P2 (r2/n3)" # not latest consumer version
      expect(rows).to_not include "C1 P1 (r2/n1)" # not latest consumer version
      expect(database[:latest_matrix].count).to eq 2
    end
  end
end
