require "pact_broker/doc/controllers/app"

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

  let(:index_response) { get "/", {}, { "HTTP_ACCEPT" => "application/hal+json" } }
  let(:index_body) { JSON.parse(index_response.body) }
  let(:docs_missing_string) { "No documentation exists"}

  it "returns a known message when the documentation doesn't exist" do
    get "/docs/does-not-exist?context=index", {}, { "HTTP_ACCEPT" => "text/html" }
    expect(last_response.body).to include docs_missing_string
  end

  it "has a document for each relation" do
    relations_that_should_have_docs = index_body["_links"].keys - ["self", "curies", "beta:provider-pacts-for-verification"]
    relations_without_docs = {}

    relations_that_should_have_docs.each do | relation |
      path = "/docs/#{relation.split(":", 2).last}?context=index"
      get path, {}, { "HTTP_ACCEPT" => "text/html" }
      if last_response.body.include?(docs_missing_string)
        relations_without_docs[relation] = last_response.status
      end
    end

    expect(relations_without_docs).to eq({})
  end
end
