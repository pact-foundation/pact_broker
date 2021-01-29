require 'pact_broker/api/resources/default_base_resource'
require 'pact_broker/application_context'

module PactBroker
  module Api
    module Resources
      describe DefaultBaseResource do
        before do
          allow(env).to receive(:[]).with("pactbroker.base_url").and_return(nil)
        end
        let(:request) { double('request', body: body, uri: uri, base_uri: URI("http://example.org/"), env: env, path_info: path_info).as_null_object }
        let(:path_info) { { application_context: application_context, key1: "foo%20bar", key2: :value2, key3: 1.2 }}
        let(:application_context) { PactBroker::ApplicationContext.default_application_context }
        let(:response) { double('response').as_null_object }
        let(:uri) { URI('http://example.org/path?query') }
        let(:body) { double('body', to_s: body_string) }
        let(:body_string) { '' }
        let(:env) { double('env').as_null_object }

        subject(:resource) { BaseResource.new(request, response) }

        its(:resource_url) { is_expected.to eq 'http://example.org/path' }

        describe "identifier_from_path" do
          its(:identifier_from_path) { is_expected.to eq key1: "foo bar", key2: :value2, key3: 1.2 }
        end

        describe "params" do
          let(:body_string) { { foo: 'bar' }.to_json }

          context "when the body is invalid JSON" do
            let(:body_string) { '{' }

            it "raises an error" do
              expect { subject.params }.to raise_error InvalidJsonError
            end
          end

          context "when the body is empty and a default is provided" do
            let(:body_string) { '' }

            it "returns the default" do
              expect(subject.params(default: 'foo')).to eq 'foo'
            end
          end

          context "when the body is empty and no default is provided" do
            let(:body_string) { '' }

            it "raises an error" do
              expect { subject.params }.to raise_error InvalidJsonError
            end
          end

          context "when symbolize_names is not set" do
            it "symbolizes the names" do
              expect(subject.params.keys).to eq [:foo]
            end
          end

          context "when symbolize_names is true" do
            it "symbolizes the names" do
              expect(subject.params(symbolize_names: true).keys).to eq [:foo]
            end
          end

          context "when symbolize_names is false" do
            it "does not symbolize the names" do
              expect(subject.params(symbolize_names: false).keys).to eq ['foo']
            end
          end
        end

        describe "options" do
          subject { options "/"; last_response }

          it "returns a list of allowed methods" do
            expect(subject.headers['Access-Control-Allow-Methods']).to eq "GET, OPTIONS"
          end
        end

        describe "resource_url" do
          let(:uri) { URI('http://example.org/path/?query') }

          it "cleans the query and trailing slash" do
            expect(subject.resource_url).to eq "http://example.org/path"
          end
        end

        describe "base_url" do
          before do
            allow(env).to receive(:[]).with("pactbroker.base_url").and_return("http://rack")
          end

          context "when pactbroker.base_url is set on the env" do
            it "uses that" do
              expect(subject.base_url).to eq "http://rack"
            end
          end

          context "when the rack env value is not set" do
            before do
              allow(env).to receive(:[]).with("pactbroker.base_url").and_return(nil)
            end

            it "returns the base URL from the request" do
              expect(subject.base_url).to eq "http://example.org"
            end
          end
        end

        describe "decorator_options" do
          before do
            allow(env).to receive(:[]).with("QUERY_STRING").and_return("foo=bar")
          end

          context "with no overrides" do
            it "returns the default decorator options" do
              expect(subject.decorator_options).to eq(
                user_options: {
                  base_url: "http://example.org",
                  resource_url: "http://example.org/path",
                  env: env,
                  resource_title: nil,
                  query_string: "foo=bar"
                }
              )
            end
          end

          context "with overrides" do
            it "returns the default decorator options" do
              expect(subject.decorator_options(resource_title: "foo", something: "else")).to eq(
                user_options: {
                  base_url: "http://example.org",
                  resource_url: "http://example.org/path",
                  env: env,
                  resource_title: "foo",
                  something: "else",
                  query_string: "foo=bar"
                }
              )
            end
          end
        end

        describe "forbidden?" do
          context "with the resource_authorizer configured" do
            let(:application_context) { PactBroker::ApplicationContext.default_application_context(resource_authorizer: resource_authorizer) }
            let(:resource_authorizer) { double('resource_authorizer', call: allowed) }
            let(:allowed) { true }

            it "calls the resource authorizer" do
              expect(resource_authorizer).to receive(:call).with(resource)
              resource.forbidden?
            end

            context "when the authorizer returns true" do
              it "returns false" do
                expect(resource.forbidden?).to eq false
              end
            end

            context "when the authorizer returns false" do
              let(:allowed) { false }

              it "returns true" do
                expect(resource.forbidden?).to eq true
              end
            end
          end
        end

        context "with no resource_authorizer configured" do
          it "returns false" do
            expect(resource.forbidden?).to eq false
          end
        end
      end

      ALL_RESOURCES = ObjectSpace.each_object(::Class)
        .select { |klass| klass < DefaultBaseResource }
        .select { |klass| !klass.name.end_with?("BaseResource") }

      ALL_RESOURCES.each do | resource_class |
        describe resource_class do
          before do
            # stub out all path info params for pf
            allow(path_info).to receive(:[]).and_return('1')
            allow(path_info).to receive(:[]).with(:application_context).and_return(application_context)
          end
          let(:application_context) { PactBroker::ApplicationContext.default_application_context(before_resource: before_resource, after_resource: after_resource) }
          let(:request) { double('request', uri: URI("http://example.org"), path_info: path_info).as_null_object }
          let(:path_info) { {} }
          let(:response) { double('response').as_null_object }
          let(:resource) { resource_class.new(request, response) }
          let(:before_resource) { double('before_resource', call: nil) }
          let(:after_resource) { double('after_resource', call: nil) }

          it "includes OPTIONS in the list of allowed_methods" do
            expect(resource.allowed_methods).to include "OPTIONS"
          end

          it "calls super in its constructor" do
            expect(application_context.before_resource).to receive(:call)
            expect(PactBroker.configuration.before_resource).to receive(:call)
            resource
          end

          it "calls super in finish_request" do
            expect(application_context.after_resource).to receive(:call)
            expect(PactBroker.configuration.after_resource).to receive(:call)
            resource.finish_request
          end

          it "has a policy_name method" do
            expect(resource).to respond_to(:policy_name)
          end
        end
      end
    end
  end
end
