require "pact_broker/db/data_migrations/migrate_webhook_headers"

module PactBroker
  module DB
    module DataMigrations
      describe MigrateWebhookHeaders, migration: true do
        describe ".call" do
          before do
            PactBroker::TestDatabase.migrate(20190602)
            webhook_header_1
            webhook_header_2
            webhook_header_3
          end

          let(:now) { DateTime.new(2018, 2, 2) }

          let(:webhook_1) do
            create(:webhooks, {
              uuid: "1",
              method: "POST",
              url: "http://example.org",
              body: nil,
              is_json_request_body: false,
              enabled: true,
              created_at: now,
              updated_at: now
            })
          end
          let(:webhook_header_1) do
            create(:webhook_headers, {
              name: "Foo",
              value: "bar",
              webhook_id: webhook_1[:id]
            }, nil)
          end

          let(:webhook_header_2) do
            create(:webhook_headers, {
              name: "Wiffle",
              value: "meep",
              webhook_id: webhook_1[:id]
            }, nil)
          end

          let(:webhook_2) do
            create(:webhooks, {
              uuid: "2",
              method: "POST",
              url: "http://example.org",
              body: nil,
              is_json_request_body: false,
              enabled: true,
              created_at: now,
              updated_at: now
            })
          end

          let(:webhook_header_3) do
            create(:webhook_headers, {
              name: "Foo2",
              value: "bar2",
              webhook_id: webhook_2[:id]
            }, nil)
          end

          subject { MigrateWebhookHeaders.call(database) }

          it "migrates the webhook headers from individual rows to json on the webhook row" do
            subject
            expect(JSON.parse(database[:webhooks].first[:headers])).to eq "Foo" => "bar", "Wiffle" => "meep"
            expect(JSON.parse(database[:webhooks].order(:id).last[:headers])).to eq "Foo2" => "bar2"
            expect(database[:webhook_headers].count).to eq 0
          end
        end
      end
    end
  end
end
