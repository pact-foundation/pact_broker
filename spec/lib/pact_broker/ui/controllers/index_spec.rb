require "rack/test"
require "pact_broker/ui/controllers/index"
require "pact_broker/index/service"

module PactBroker
  module UI
    module Controllers
      describe Index do

        include Rack::Test::Methods

        let(:app) { Index }

        describe "/" do
          describe "GET" do

            before do
              td
                .create_consumer("Test App")
                .create_provider("Test API")
                .create_consumer_version
                .create_pact
                .create_webhook
                .create_verification

              td
                .create_consumer("Example App")
                .create_provider("Example API")
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
                get "/", { page: "2", pageSize: "40" }
              end
            end

            context "when pagination parameters are not present" do
              context "when tags=true" do
                it "passes through default pagination parameters to the search with page_size=30" do
                  expect(PactBroker::Index::Service).to receive(:find_index_items).with(hash_including(page_number: 1, page_size: 30))
                  get "/", { tags: "true" }
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
                get "/", { tags: "true" }
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

            context "when parameter search presents" do
              context "when it is blank" do
                it "ignores it" do
                  get "/", { search_name: "" }

                  expect(last_response.body).to include("Example App")
                  expect(last_response.status).to eq(200)
                end
              end

              context "when it is NOT blank and the pacticipant name exists" do
                it "returns the pacticipant which matches the query" do
                  get "/", { search: "app" }

                  expect(last_response.body).to include("Example App")
                  expect(last_response.status).to eq(200)
                end
              end

              context "when it is NOT blank but the pacticipant name does NOT exist" do
                it "returns no pacts" do
                  get "/", { search: "does not exist" }

                  expect(last_response.body).not_to include("does not exit")
                  expect(last_response.body).not_to include("Example App")
                  expect(last_response.body).not_to include("Test App")
                  expect(last_response.status).to eq(200)
                end
              end
            end
          end
        end
      end
    end
  end
end
