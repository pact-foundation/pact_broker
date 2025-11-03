require "rack/test"

module PactBroker
  module Ui
    module Controllers
      describe Clusters do

        include Rack::Test::Methods

        let(:app) { Clusters }

        describe "/" do
          describe "GET" do

            xit "does something" do
              get "/"
              puts last_response.body
            end

          end
        end
      end
    end
  end
end