require "webmachine"
require "webmachine/adapters/rack_mapped"
require "rack/test"

module Webmachine
  module Adapters
    class TestResource < Webmachine::Resource
      def allowed_methods
        ["POST"]
      end

      def process_post
        response.body = request.env["FOO"]
        true
      end
    end

    describe Rack do
      include ::Rack::Test::Methods

      let(:app) do
        pact_api = Webmachine::Application.new do |app|
          app.routes do
            add(["test"], TestResource)
          end
        end

        pact_api.configure do |config|
          config.adapter = :RackMapped
        end

        pact_api.adapter
      end

      let(:rack_env) do
        {
          "FOO" => "foo"
        }
      end

      subject { post("/test", nil, rack_env) }

      it "passes the rack env through on the request" do
        expect(subject.status).to eq 200
        expect(subject.body).to eq "foo"
      end
    end
  end
end
