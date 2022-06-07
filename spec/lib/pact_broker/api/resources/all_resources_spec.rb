require "pact_broker/api/resources"
require "pact_broker/application_context"

module PactBroker
  module Api
    module Resources
      ALL_RESOURCES = ObjectSpace.each_object(::Class)
        .select { |klass| klass < BaseResource }
        .select { |klass| !klass.name.end_with?("BaseResource") }
        .sort_by(&:name)

      ALL_RESOURCES.each do | resource_class |
        describe resource_class do
          before do
            # stub out all path info params for pf
            allow(path_info).to receive(:[]).and_return("1")
            allow(path_info).to receive(:[]).with(:application_context).and_return(application_context)
          end
          let(:application_context) { PactBroker::ApplicationContext.default_application_context(before_resource: before_resource, after_resource: after_resource) }
          let(:request) { double("request", uri: URI("http://example.org"), path_info: path_info, body: body).as_null_object }
          let(:body) { "{}" }
          let(:path_info) { { pacticipant_name: "foo", pacticipant_version_number: "1" } }
          let(:response) { double("response").as_null_object }
          let(:resource) { resource_class.new(request, response) }
          let(:before_resource) { double("before_resource", call: nil) }
          let(:after_resource) { double("after_resource", call: nil) }

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

          it "has a policy_record method" do
            expect(resource).to respond_to(:policy_record)
          end

          describe "malformed_request?" do
            context "an invalid UTF-8 character is used in the request body" do
              before do
                allow(request).to receive(:put?).and_return(true)
                allow(request).to receive(:really_put?).and_return(true)
                allow(request).to receive(:post?).and_return(true)
                allow(request).to receive(:patch?).and_return(true)
              end

              let(:body) { "ABCDEFG\x8FDEF" }

              it "returns true when it accepts a content type that includes json" do
                if resource.content_types_accepted.collect(&:first).any?{ |ct| ct.include?("json") }
                  expect(resource.malformed_request?).to eq true
                end
              end
            end
          end
        end
      end
    end
  end
end
