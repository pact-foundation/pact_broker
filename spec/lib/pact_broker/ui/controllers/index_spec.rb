require 'rack/test'
require 'pact_broker/ui/controllers/index'
require 'pact_broker/index/service'

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

            context "when pagination parameters are present" do
              it "passes through pagination parameters to the search" do
                expect(PactBroker::Index::Service).to receive(:find_index_items).with(hash_including(page_number: 2, page_size: 40))
                get "/", { page: '2', pageSize: '40' }
              end
            end

            context "when pagination parameters are not present" do
              context "when tags=true" do
                it "passes through default pagination parameters to the search with page_size=30" do
                  expect(PactBroker::Index::Service).to receive(:find_index_items).with(hash_including(page_number: 1, page_size: 30))
                  get "/", { tags: 'true' }
                end
              end

              context "when not tags=true" do
                it "passes through default pagination parameters to the search with page_size=100" do
                  expect(PactBroker::Index::Service).to receive(:find_index_items).with(hash_including(page_number: 1, page_size: 100))
                  get "/"
                end
              end
            end

            context "with tags=true" do
              before do
                allow(PactBroker::Index::Service).to receive(:find_index_items).and_return([])
              end

              it "passes tags: true to the IndexService" do
                expect(PactBroker::Index::Service).to receive(:find_index_items).with(hash_including(tags: true))
                get "/", { tags: 'true' }
              end
            end

            context "with tags[]=prod" do
              before do
                allow(PactBroker::Index::Service).to receive(:find_index_items).and_return([])
              end

              it "passes tags: ['prod'] to the IndexService" do
                expect(PactBroker::Index::Service).to receive(:find_index_items).with(hash_including(tags: ["prod"]))
                get "/", { tags: ["prod"] }
              end
            end

            context "with tags=prod" do
              before do
                allow(PactBroker::Index::Service).to receive(:find_index_items).and_return([])
              end

              it "passes tags: ['prod'] to the IndexService" do
                expect(PactBroker::Index::Service).to receive(:find_index_items).with(hash_including(tags: ["prod"]))
                get "/", { tags: "prod" }
              end
            end
          end
        end
      end
    end
  end
end
