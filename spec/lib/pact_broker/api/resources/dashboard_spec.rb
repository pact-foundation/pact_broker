require "pact_broker/api/resources/dashboard"

module PactBroker
  module Api
    module Resources

      describe Dashboard do

        let(:path) { "/dashboard" }
        subject { get path; last_response }

      end
    end
  end
end
