require "pact_broker/api/paths"

module PactBroker
  module Api
    module Paths
      describe "is_badge_path?" do

        BADGE_ROUTES = PactBroker.routes.select{ | route | route.path_include?("/badge") }.collect(&:path)

        BADGE_ROUTES.each do | path |
          context "for #{path}" do
            it "returns truthy" do
              expect(Paths.is_badge_path?(path)).to be_truthy
            end
          end
        end
      end
    end
  end
end
