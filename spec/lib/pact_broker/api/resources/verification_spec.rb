require 'pact_broker/api/resources/verification'

module PactBroker
  module Api
    module Resources
      describe Verification do
        context "when someone tries to get all the verifications for a pact" do
          subject { get("/pacts/provider/Bar/consumer/Foo/pact-version/1/verification-results/all") }

          it "tells them to use the matrix" do
            expect(subject.status).to eq 404
            expect(subject.body).to include "Matrix"
          end
        end
      end
    end
  end
end
