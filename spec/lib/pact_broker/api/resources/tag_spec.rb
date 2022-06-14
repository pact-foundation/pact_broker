require "pact_broker/api/resources/tag"

module PactBroker
  module Api
    module Resources
      describe Tag do
        let(:tag) { double("PactBroker::Domain::Tag", version: version) }
        let(:version) { double("version") }
        let(:tag_decorator) { instance_double("PactBroker::Api::Decorators::TagDecorator", :to_json => tag_json) }
        let(:tag_json) { {"some" => "tag"}.to_json }
        let(:tag_attributes) {
          {
            :pacticipant_name => "Condor",
            :pacticipant_version_number => "1.3.0",
            :tag_name => "prod"
          }
        }

        describe "DELETE" do
          before do
            allow(Tags::Service).to receive(:find).and_return(tag)
            allow(Tags::Service).to receive(:delete)
          end

          subject { delete("/pacticipants/Condor/versions/1.3.0/tags/prod" ) }

          context "when the tag exists" do
            it "deletes the tag by name" do
              expect(Tags::Service).to receive(:delete) .with(hash_including(tag_attributes))
              subject
            end

            it "returns a 204 OK" do
              subject
              expect(last_response.status).to eq 204
            end
          end

          context "when the tag doesn't exist" do
            let(:tag) { nil }

            it "returns a 404 Not Found" do
              subject
              expect(last_response.status).to eq 404
            end
          end

          context "when an error occurs" do
            before do
              allow(Tags::Service).to receive(:delete).and_raise("An error")
            end

            let(:response_body) { JSON.parse(last_response.body, symbolize_names: true) }

            it "returns a 500 Internal Server Error" do
              subject
              expect(last_response.status).to eq 500
            end

            it "returns an error message" do
              subject
              expect(response_body[:error][:message]).to eq "An error"
            end
          end
        end

        describe "GET" do
          before do
            allow(Tags::Service).to receive(:find).and_return(tag)
            allow(PactBroker::Api::Decorators::TagDecorator).to receive(:new).and_return(tag_decorator)
          end

          subject { get("/pacticipants/Condor/versions/1.3.0/tags/prod" ) }

          context "when the tag exists" do

            it "renders the tag" do
              subject
              expect(last_response.body).to eq tag_json
            end

            it "returns a success response" do
              subject
              expect(last_response).to be_successful
            end
          end

          context "when the tag does not exist" do
            let(:tag) { nil }

            it "returns a 404" do
              subject
              expect(last_response.status).to eq 404
            end
          end
        end

        describe "PUT" do
          before do
            allow_any_instance_of(PactBroker::Api::Resources::Tag).to receive(:tag_url).and_return(tag_url)
            allow(Tags::Service).to receive(:find).and_return(tag)
            allow(PactBroker::Api::Decorators::TagDecorator).to receive(:new).and_return(tag_decorator)
            allow(deployed_version_service).to receive(:maybe_create_deployed_version_for_tag).and_return("uuid")
          end

          let(:deployed_version_service) { class_double("PactBroker::Deployments::DeployedVersionService").as_stubbed_const }
          let(:tag_url) { "http://example.org/tag/url"}
          let(:create_deployed_versions_for_tags) { false }
          let(:request_body) { nil }

          subject { put("/pacticipants/Condor/versions/1.3.0/tags/prod", request_body, "CONTENT_LENGTH" => "0", "CONTENT_TYPE" => "application/json") }

          it "returns a success response" do
            subject
            expect(last_response).to be_successful
          end

          context "with a malformed JSON body" do
            let(:request_body) { "{" }

            its(:status) { is_expected.to eq 400 }
          end

          context "when the tag already exists" do
            it "returns a 200" do
              subject
              expect(last_response.status).to be 200
            end

            it "maybe creates a deployed version" do
              expect(deployed_version_service).to receive(:maybe_create_deployed_version_for_tag).with(version, "prod")
              subject
            end

            it "renders the tag" do
              expect(tag_decorator).to receive(:to_json).with(user_options: hash_including(base_url: "http://example.org"))
              subject
              expect(last_response.body).to eq tag_json
            end
          end

          context "when the tag does not exist" do
            before do
              allow(Tags::Service).to receive(:find).and_return(nil)
              allow(Tags::Service).to receive(:create).and_return(tag)
            end

            it "creates the tag" do
              expect(Tags::Service).to receive(:create).with(hash_including(tag_attributes))
              subject
            end

            it "maybe creates a deployed version" do
              expect(deployed_version_service).to receive(:maybe_create_deployed_version_for_tag).with(version, "prod")
              subject
            end

            it "returns a 201" do
              subject
              expect(last_response.status).to be 201
            end

            it "renders the tag" do
              expect(tag_decorator).to receive(:to_json).with(user_options: hash_including(base_url: "http://example.org"))
              subject
              expect(last_response.body).to eq tag_json
            end
          end
        end
      end
    end
  end
end
