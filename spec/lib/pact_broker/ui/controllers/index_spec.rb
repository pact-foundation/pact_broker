require 'spec_helper'
require 'pact_broker/ui/controllers/index'

require 'rack/test'

module PactBroker
  module UI
    module Controllers
      describe Index do

        include Rack::Test::Methods

        let(:app) { Index }

        describe "/" do
          describe "GET" do

            before do
              TestDataBuilder.new
                .create_consumer
                .create_provider
                .create_consumer_version
                .create_pact
                .create_webhook
                .create_verification
            end

            it "does something" do
              get "/"
              expect(last_response.body).to include("Pacts")
              expect(last_response.status).to eq(200)
            end

            context "with tags=true" do
              before do
                allow(PactBroker::Index::Service).to receive(:find_index_items).and_return([])
              end

              it "passes tags: true to the IndexService" do
                expect(PactBroker::Index::Service).to receive(:find_index_items).with(tags: true)
                get "/", { tags: 'true' }
              end
            end

            context "with tags[]=prod" do
              before do
                allow(PactBroker::Index::Service).to receive(:find_index_items).and_return([])
              end

              it "passes tags: ['prod'] to the IndexService" do
                expect(PactBroker::Index::Service).to receive(:find_index_items).with(tags: ["prod"])
                get "/", { tags: ["prod"] }
              end
            end

            context "with tags=prod" do
              before do
                allow(PactBroker::Index::Service).to receive(:find_index_items).and_return([])
              end

              it "passes tags: ['prod'] to the IndexService" do
                expect(PactBroker::Index::Service).to receive(:find_index_items).with(tags: ["prod"])
                get "/", { tags: "prod" }
              end
            end
          end
        end
      end
    end
  end
end
