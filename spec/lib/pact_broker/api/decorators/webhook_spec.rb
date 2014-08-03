require 'spec_helper'
require 'pact_broker/api/decorators/webhook'



module PactBroker
  module Api
    module Decorators
      describe WebhookDecorator do

        let(:hash) do
          {
            method: 'POST',
            url: 'http://example.org/hook',
            headers: {'Content-Type' => 'application/json'}
            body: { some: 'body' }
          }
        end

      end
    end
  end
end