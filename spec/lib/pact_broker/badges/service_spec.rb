require 'pact_broker/badges/service'
require 'webmock/rspec'

module PactBroker
  module Badges
    module Service
      describe "#pact_verification_badge" do
        let!(:http_request) do
          stub_request(:get, "https://img.shields.io/badge/Foo--Bar__Thing%20Service%20Pact-verified-brightgreen.svg").
            to_return(:status => 200, :body => "body")
        end

        let(:pacticipant_name) { "Foo-Bar_Thing Service" }

        let(:svg) { PactBroker::Badges::Service.pact_verification_badge pacticipant_name, :success }

        it "gets the svg" do
           expect(svg).to eq "body"
        end
      end
    end
  end
end
