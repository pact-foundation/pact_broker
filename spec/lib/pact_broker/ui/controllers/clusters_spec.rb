require 'spec_helper'
require 'pact_broker/ui/controllers/clusters'
require 'rack/test'

module PactBroker
  module UI
    module Controllers
      describe Clusters do

        include Rack::Test::Methods

        let(:app) { Clusters }

        describe "/" do
          describe "GET" do

            it "does something" do
              get "/"
              puts last_response.body
            end

          end
        end
      end
    end
  end
end