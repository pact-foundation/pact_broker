require 'rack/pact_broker/use_when'
require 'rack/test'

module Rack
  module PactBroker
    describe UseWhen do

      using Rack::PactBroker::UseWhen
      include Rack::Test::Methods

      class TestMiddleware
        def initialize(app, additional_headers)
          @app = app
          @additional_headers = additional_headers
        end

        def call(env)
          status, headers, body = @app.call(env)
          [status, headers.merge(@additional_headers), body]
        end
      end

      let(:app) do
        target_app = -> (_env) { [200, {}, []] }
        builder = Rack::Builder.new
        condition = ->(env) { env['PATH_INFO'] == '/match' }
        builder.use_when condition, TestMiddleware, { "Foo" => "Bar" }
        builder.run target_app
        builder.to_app
      end

      context "when the condition matches" do
        subject { get '/match' }

        it "uses the middleware" do
          expect(subject.headers).to include "Foo" => "Bar"
        end
      end

      context "when the condition does not match" do
        subject { get '/no-match' }

        it "does not use the middleware" do
          expect(subject.headers.keys).to_not include "Foo"
        end
      end
    end
  end
end
