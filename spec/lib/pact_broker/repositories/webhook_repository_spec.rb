require 'spec_helper'
require 'pact_broker/repositories/webhook_repository'

module PactBroker
  module Repositories
    describe WebhookRepository do

      describe "#save" do

        let(:webhook) { Models::Webhook.new(consumer_id: consumer_id)}

      end

    end
  end
end