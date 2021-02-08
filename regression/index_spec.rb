require 'pact_broker/domain'
require 'pact_broker/policies'
require 'pact_broker/ui/app'

RSpec.describe "regression tests for index page", no_db_clean: true, regression: true, focus: true do
  context "HTML" do
    let(:app) { PactBroker::UI::App.new }

    it "has the same response without tags" do
      response = get("/", nil, { "HTTP_ACCEPT" => "text/html" } )
      Approvals.verify(response.body, :name => "index_html", format: :html)
    end

    it "has the same response with tags" do
      response = get("/", { "tags" => "true", "pageNumber" => "1", "pageSize" => "100"}, { "HTTP_ACCEPT" => "text/html" } )
      Approvals.verify(response.body, :name => "index_html_with_tags", format: :html)
    end
  end

  context "JSON" do
    it "has the same response" do
      response = get("/dashboard", { "HTTP_ACCEPT" => "application/hal+json" } )
      Approvals.verify(JSON.parse(response.body), :name => "index_json", format: :json)
    end
  end
end
