require "pact_broker/app"
require "support/test_database"

module PactBroker
  describe App do
    before do
      td.create_pact_with_hierarchy("Some Consumer", "1.0", "Some Provider").and_return(:pact)
    end

    let(:hal_browser_enabled) { true }
    let(:network_url) { "/pacticipants/Some%20Consumer/network" }
    let(:group_url) { "/groups/Some%20Consumer" }
    let(:enable_diagnostic_endpoints) { false }

    let(:app) do
      PactBroker::App.new do | config |
        config.auto_migrate_db = false
        config.use_hal_browser = hal_browser_enabled
        config.database_connection = ::PactBroker::TestDatabase.connection_for_test_database
        config.enable_diagnostic_endpoints = enable_diagnostic_endpoints
      end
    end

    it "exposes a favicon.ico file" do
      get "/favicon.ico"
      expect(last_response.headers["Content-Type"]).to eq "image/x-icon"
    end

    context "when Accept includes text/html" do
      let(:env) { {"HTTP_ACCEPT" => "text/html"} }

      subject { get(path, "", env) }

      describe "a request for root" do
        let(:path) { "/" }

        it "returns the relationships page" do
          expect(subject.status).to eq 200
          expect(subject.headers["Content-Type"]).to include "text/html"
          expect(subject.body).to include "Pacts"
        end

      end

      describe "a request for /ui/relationships" do
        let(:path) { "/ui/relationships/" }

        it "returns the relationships page" do
          expect(subject.status).to eq 200
          expect(subject.headers["Content-Type"]).to include "text/html"
          expect(subject.body).to include "Pacts"
        end
      end

      describe "a request for /pacticipants/:pacticipant_name" do
        let(:path) { "/pacticipants/Some%20Consumer" }

        it "returns the group page" do
          expect(subject.status).to eq 200
          expect(subject.headers["Content-Type"]).to include "text/html"
          expect(subject.body).to include "Some Consumer"
        end

        it "does not screw up the HTML escaping, haven't you heard of semantic versioning padrino?? Seriously." do
          expect(subject.body).to include "<html"
          expect(subject.body).to_not include "&lt;html"
        end
      end

      describe "a request for /doc/:rel_name" do
        let(:path) { "/doc/webhooks" }

        it "returns the HAL docs for the given rel" do
          expect(subject.status).to eq 200
          expect(subject.headers["Content-Type"]).to include "text/html"
          expect(subject.body).to include "Webhooks"
        end
      end

      describe "a request the group containing a pacticipant" do
        let(:path) { network_url }

        it "returns the HTML representation of the pacticipant" do
          expect(subject.status).to eq 200
          expect(subject.headers["Content-Type"]).to include "text/html"
          expect(subject.body).to include "Network Graph"
        end
      end

      describe "a request for a path that does not exist" do
        let(:path) { "/foo" }

        it "returns a 404" do
          expect(subject.status).to eq 404
          expect(subject.headers["Content-Type"]).to include "text/html"
        end
      end

      context "when the HALBrowser is enabled" do
        context "when application/hal+json is also specified as an Accept" do
          let(:env) { {"HTTP_ACCEPT" => "text/html;application/hal+json"} }
          let(:path) { "/something" }

          it "redirects to the HAL Browser" do
            expect(subject.status).to eq 303
            expect(subject.headers["Location"]).to eq "/hal-browser/browser.html#/something"
          end
        end
      end

      context "when the HALBrowser is not enabled" do
        context "when application/hal+json is also specified as an Accept" do
          let(:hal_browser_enabled) { false }
          let(:env) { {"HTTP_ACCEPT" => "text/html;application/hal+json"} }
          let(:path) { "/something" }

          it "does not redirect to the HAL Browser" do
            expect(subject.status).to_not eq 303
          end
        end
      end

      context "when a .csv extension is specified" do
        let(:path) { "/groups/Some%20Consumer.csv" }

        it "returns the CSV Content-Type" do
          expect(subject.status).to eq 200
          expect(subject.headers["Content-Type"]).to eq "text/csv;charset=utf-8"
        end
      end
    end

    context "when the Accept header is */* (default curl)" do
      let(:env) { { "HTTP_ACCEPT" => "*/*" } }

      subject { get path, "", env; last_response }

      describe "a request for root" do
        let(:path) { "/" }

        it "returns an API response" do
          expect(subject.status).to eq 200
          expect(subject.headers["Content-Type"]).to include "application/hal+json"
        end
      end
    end

    context "when no Accept header is specified" do
      let(:env) { {} }

      subject { get path, "", env }

      describe "a request for root" do
        let(:path) { "/" }

        it "returns an API response" do
          expect(subject.status).to eq 200
          expect(subject.headers["Content-Type"]).to_not include "html"
        end
      end

      describe "a request the group containing a pacticipant" do
        let(:path) { group_url }

        it "returns the API representation of the group" do
          expect(subject.status).to eq 200
          expect(subject.headers["Content-Type"]).to_not include "html"
        end
      end

      describe "a request for a stylesheet" do
        let(:path) { "/stylesheets/pact.css" }

        it "returns the stylesheet" do
          expect(subject.status).to eq 200
          expect(subject.headers["Content-Type"]).to include "text/css"
        end
      end
    end

    context "when the diagnostic endpoints are enabled" do
      let(:enable_diagnostic_endpoints) { true }

      it "returns a 200 to /diagnostic/status/heartbeat" do
        get "/diagnostic/status/heartbeat"
        expect(last_response.status).to eq 200
      end
    end

    context "when the diagnostic endpoints are not enabled" do
      it "returns a 404 to /diagnostic/status/heartbeat" do
        get "/diagnostic/status/heartbeat"
        expect(last_response.status).to eq 404
      end
    end

    describe "when a resource identifier contains a slash" do
      let(:path) { "/pacticipants/Foo/versions/1.2.3/tags/feat%2Fbar" }

      subject { put(path, nil, {"CONTENT_TYPE" => "application/json"}) }

      it "returns a success status" do
        expect(subject.status).to eq 201
      end
    end
  end
end
