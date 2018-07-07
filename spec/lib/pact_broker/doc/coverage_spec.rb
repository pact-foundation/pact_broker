require 'pact_broker/doc/controllers/app'

RSpec.describe "the HAL docs for the index" do

  let(:app) do
    Rack::Builder.new do
      map "/docs" do
        run PactBroker::Doc::Controllers::App
      end
      map "/" do
        run PactBroker::API
      end
    end
  end

  let(:index_response) { get "/", {}, { 'HTTP_ACCEPT' => 'application/hal+json' } }
  let(:index_body) { JSON.parse(index_response.body) }

  it "has a document for each relation" do
    relations_that_should_have_docs = index_body['_links'].keys - ['self', 'curies']
    relations_without_docs = {}

    relations_that_should_have_docs.each do | relation |
      path = "/docs/#{relation.split(":", 2).last}"
      get path, {}, { 'HTTP_ACCEPT' => 'text/html' }
      if last_response.status != 200
        relations_without_docs[relation] = last_response.status
      end
    end

    expect(relations_without_docs).to eq({})
  end
end
