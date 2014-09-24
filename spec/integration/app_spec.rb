require 'spec_helper'
require 'pact_broker/app'
require 'db'

module PactBroker

  describe App do

    before do
      ProviderStateBuilder.new.create_pact_with_hierarchy 'Some Consumer', '1.0', 'Some Provider'
    end

    let(:hal_browser_enabled) { true }
    let(:group_url) { '/groups/Some%20Consumer' }

    let(:app) do
      app = PactBroker::App.new do | config |
        config.auto_migrate_db = false
        config.use_hal_browser = hal_browser_enabled
        config.database_connection = ::DB::PACT_BROKER_DB
      end

    end

    context "when Accept includes text/html" do
      let(:env) { {'HTTP_ACCEPT' => 'text/html'} }

      subject { get path, '', env; last_response }

      describe "a request for root" do

        let(:path) { '/' }

        it "redirects to /ui/relationships" do
          expect(subject.status).to eq 303
          expect(subject.headers['Location']).to eq 'ui/relationships'
        end

      end

      describe "a request for /ui/relationships" do
        let(:path) { '/ui/relationships/' }

        it "returns the relationships page" do
          expect(subject.status).to eq 200
          expect(subject.headers['Content-Type']).to include 'text/html'
          expect(subject.body).to include 'Relationships'
        end
      end

      describe "a request for /groups/:pacticipant_name" do
        let(:path) { '/groups/Some%20Consumer' }

        it "returns the group page" do
          expect(subject.status).to eq 200
          expect(subject.headers['Content-Type']).to include 'text/html'
          expect(subject.body).to include 'Network graph'
          expect(subject.body).to include 'Some Consumer'
        end
      end

      describe "a request for /doc/:rel_name" do
        let(:path) { '/doc/webhooks' }

        it "returns the HAL docs for the given rel" do
          expect(subject.status).to eq 200
          expect(subject.headers['Content-Type']).to include 'text/html'
          expect(subject.body).to include 'Webhooks'
        end
      end

      describe "a request the group containing a pacticipant" do
        let(:path) { group_url }

        it "returns the HTML representation of the group" do
          expect(subject.status).to eq 200
          expect(subject.headers['Content-Type']).to include 'text/html'
          expect(subject.body).to include 'Network graph'
        end
      end

      describe "a request for a path that does not exist" do
        let(:path) { '/foo' }

        it "returns a 404" do
          expect(subject.status).to eq 404
          expect(subject.headers['Content-Type']).to include 'text/html'
        end
      end

      context "when the HALBrowser is enabled" do
        context "when application/hal+json is also specified as an Accept" do

          let(:env) { {'HTTP_ACCEPT' => 'text/html;application/hal+json'} }
          let(:path) { '/something' }

          it "redirects to the HAL Browser" do
            expect(subject.status).to eq 303
            expect(subject.headers['Location']).to eq '/hal-browser/browser.html#/something'
          end
        end
      end

      context "when the HALBrowser is not enabled" do
        context "when application/hal+json is also specified as an Accept" do

          let(:hal_browser_enabled) { false }
          let(:env) { {'HTTP_ACCEPT' => 'text/html;application/hal+json'} }
          let(:path) { '/something' }

          it "does not redirect to the HAL Browser" do
            expect(subject.status).to_not eq 303
          end
        end
      end

    end

    context "when no Accept header is specified" do

      let(:env) { {} }
      subject { get path, '', env; last_response }

      describe "a request for root" do
        let(:path) { "/" }

        it "returns an API response" do
          expect(subject.status).to eq 200
          expect(subject.headers['Content-Type']).to_not include 'html'
        end
      end

      describe "a request the group containing a pacticipant" do
        let(:path) { group_url }

        it "returns the API representation of the group" do
          expect(subject.status).to eq 200
          expect(subject.headers['Content-Type']).to_not include 'html'
        end
      end

      describe "a request for a stylesheet" do
        let(:path) { '/stylesheets/pact.css' }

        it "returns the stylesheet" do
          expect(subject.status).to eq 200
          expect(subject.headers['Content-Type']).to include 'text/css'
        end
      end

    end

  end

end