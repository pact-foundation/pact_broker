require 'spec_helper'
require 'pact_broker/models/webhook'

module PactBroker

  module Models

    describe Webhook do

      describe "#validate" do
        subject { Webhook.new(request: ) }
        context "with a nil method" do
          it "returns an error message" do

          end
        end
      end
    end

  end

end
