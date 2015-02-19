require 'spec_helper'
require 'pact_broker/diagnostic/resources/dependencies'

module PactBroker
  module Diagnostic
    module Resources
      describe Dependencies do

        describe "GET /diagnostic/status/dependencies" do

          context "when we can connect to the database" do
            it "returns a 200 response"
          end

          context "when we can't connect to the database" do
            it "returns a 500 response"
          end

          context "when there is an exception valiating the database connection" do
            it "returns a 500 response"
          end
        end
      end
    end
  end
end
