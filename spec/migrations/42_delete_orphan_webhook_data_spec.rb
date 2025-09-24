describe "creating triggered webhooks from webhook executions (migrate 36-41)", migration: true do
  before do
    PactBroker::TestDatabase.migrate(41)
  end

  let(:before_now) { DateTime.new(2016, 1, 1) }
  let(:now) { DateTime.new(2018, 2, 2) }
  let!(:consumer) { create(:pacticipants, {name: "Consumer", created_at: now, updated_at: now}) }
  let!(:provider) { create(:pacticipants, {name: "Provider", created_at: now, updated_at: now}) }
  let!(:consumer_version) { create(:versions, {number: "1.2.3", order: 1, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }
  let!(:pact_version) { create(:pact_versions, {content: {some: "json"}.to_json, sha: "1234", consumer_id: consumer[:id], provider_id: provider[:id], created_at: now}) }
  let!(:pact_publication) do
    create(:pact_publications, {
      consumer_version_id: consumer_version[:id],
      provider_id: provider[:id],
      revision_number: 1,
      pact_version_id: pact_version[:id],
      created_at: (now - 1)
    })
  end
  let!(:webhook) do
    create(:webhooks, {
      uuid: "1234",
      method: "GET",
      url: "http://www.example.org",
      consumer_id: consumer[:id],
      provider_id: provider[:id],
      is_json_request_body: false,
      created_at: now
    })
  end
  let!(:triggered_webhook) do
    create(:triggered_webhooks, {
      trigger_uuid: "12345",
      trigger_type: "publication",
      pact_publication_id: pact_publication[:id],
      webhook_id: webhook[:id],
      webhook_uuid: webhook[:uuid],
      consumer_id: consumer[:id],
      provider_id: provider[:id],
      status: "success",
      created_at: now,
      updated_at: now
    })
  end
  let!(:webhook_execution) do
    create(:webhook_executions, {
      triggered_webhook_id: triggered_webhook[:id],
      success: true,
      logs: "logs",
      created_at: now
    })
  end

  let!(:orphan_triggered_webhook) do
    create(:triggered_webhooks, {
      trigger_uuid: "12345",
      trigger_type: "publication",
      pact_publication_id: pact_publication[:id],
      webhook_id: nil,
      webhook_uuid: webhook[:uuid],
      consumer_id: consumer[:id],
      provider_id: provider[:id],
      status: "success",
      created_at: now,
      updated_at: now
    })
  end

  let!(:orphan_webhook_execution) do
    create(:webhook_executions, {
      triggered_webhook_id: orphan_triggered_webhook[:id],
      success: true,
      logs: "logs",
      created_at: now
    })
  end

  let!(:deprecated_orphan_webhook_execution) do
    create(:webhook_executions, {
      triggered_webhook_id: nil,
      webhook_id: nil,
      success: true,
      logs: "logs",
      created_at: now
    })
  end

  subject { PactBroker::TestDatabase.migrate(42) }

  it "deletes the orphan triggered webhooks" do
    expect { subject }.to change { database[:triggered_webhooks].count }.by(-1)
  end

  it "deletes the orphan webhook executions" do
    expect { subject }.to change { database[:webhook_executions].count }.by(-2)
  end
end
