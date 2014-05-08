require 'rack/test'
require 'rack/hal_browser/redirect'

module Rack
  module HalBrowser
    describe Redirect do
      include Rack::Test::Methods

      let(:inner_app) do
        ->(env) { [200, {'Content-Type' => 'text/html'}, ['All good!']] }
      end

      let(:app) { Redirect.new(inner_app) }

      it "passes non-html requests straight through" do
        get '/', {}, 'HTTP_ACCEPT' => 'application/hal+json'
        expect(last_response).to be_ok
        expect(last_response.headers['Content-Type']).to eq 'text/html'
        expect(last_response.body).to eq 'All good!'
      end

      context "when client accepts html and json" do

        it "redirects to the HAL browser" do
          get '/', {}, 'HTTP_ACCEPT' => 'text/html,application/hal+json'
          follow_redirect!
          expect(last_request.url).to eq 'http://example.org/hal-browser/browser.html'
        end

        it "passes the original request path to the HAL browser via the fragment" do
          get '/foo', {}, 'HTTP_ACCEPT' => 'text/html,application/hal+json'
          expect(last_response.headers['Location']).to eq '/hal-browser/browser.html#/foo'
        end

      end

      context "when a path is excluded" do

        let(:app) { Redirect.new(inner_app, :exclude => '/foo') }

        it "passes requests to the excluded path straight through" do
          get '/foo', {}, 'HTTP_ACCEPT' => 'text/html'
          expect(last_response).to be_ok
          expect(last_response.headers['Content-Type']).to eq 'text/html'
          expect(last_response.body).to eq 'All good!'
        end

      end

      context 'when clent uses non GET verb' do

        it "passes requests to the excluded path straight through" do
          post '/foo', {}, 'HTTP_ACCEPT' => 'text/html'
          expect(last_response).to be_ok
          expect(last_response.headers['Content-Type']).to eq 'text/html'
          expect(last_response.body).to eq 'All good!'
        end

      end

    end
  end
end
