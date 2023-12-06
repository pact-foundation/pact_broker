require "rack/pact_broker/invalid_uri_protection"
require "pact_broker/application_context"
require "pact_broker/api/decorators/custom_error_problem_json_decorator"

module Rack
  module PactBroker
    describe InvalidUriProtection do
      let(:target_app) { ->(_env){ [200, {}, []] } }
      let(:app) { InvalidUriProtection.new(target_app) }
      let(:path) { "/foo" }

      subject { get(path, {}, {"pactbroker.application_context" => ::PactBroker::ApplicationContext.default_application_context} ) }

      context "with a URI that the Ruby default URI library cannot parse" do
        let(:path) { "/badpath" }

        before do
          # Can't use or stub URI.parse because rack test uses it to execute the actual test
          allow_any_instance_of(InvalidUriProtection).to receive(:parse).and_raise(URI::InvalidURIError)
        end

        it "returns a 404" do
          expect(subject.status).to eq 404
        end
      end

      context "when the URI can be parsed" do
        it "passes the request to the underlying app" do
          expect(subject.status).to eq 200
        end

        context "when the path contains missing path segments" do
          let(:path) { "/foo//bar" }

          it "returns a 404" do
            expect(subject.status).to eq 404
          end
        end

        context "when the URI contains a new line because someone forgot to strip the result of `git rev-parse HEAD`, and I have totally never done this before myself" do
          let(:path) { "/foo%0A/bar" }

          it "returns a 422" do
            expect(subject.status).to eq 422
            expect(subject.body).to include "new line"
          end
        end

        context "when the URI contains a tab because sooner or later someone is eventually going to do this" do
          let(:path) { "/foo%09/bar" }

          it "returns a 422" do
            expect(subject.status).to eq 422
            expect(subject.body).to include "tab"
          end
        end
      end
    end
  end
end
