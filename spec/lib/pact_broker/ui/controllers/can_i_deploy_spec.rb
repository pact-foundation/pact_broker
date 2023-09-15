require "pact_broker/ui/controllers/can_i_deploy"

module PactBroker
  module UI
    module Controllers
      describe CanIDeploy do

        let(:app) { CanIDeploy }

        describe "GET" do
          before do
            td
              .create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_consumer_version_tag("main")
          end

          subject { get("/Foo/latest-version/main/can-i-deploy/to/prod") }

          it "renders the matrix page" do
            expect(subject.body).to include "The Matrix"
          end
        end
      end
    end
  end
end
