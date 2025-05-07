require "pact_broker/api/resources/pacticipant"

module PactBroker::Api
  module Resources
    describe Pacticipant do
      describe "PUT" do
        before do
          allow(PactBroker::Pacticipants::Service).to receive(:find_pacticipant_by_name).and_return(pacticpant)
        end

        let(:pacticpant) { double("pacticipant") }
        let(:path) { "/pacticipants/foo" }
        let(:headers) { {"CONTENT_TYPE" => "application/json"} }
        let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}

        subject { put(path, "", headers) }

        context "with an empty body" do
          its(:status) { is_expected.to eq 200 }
        end

        context "when content type is merge-patch+json" do
          let(:headers) { {"CONTENT_TYPE" => "application/merge-patch+json"} }
          its(:status) { is_expected.to eq 415 }
        end

        context "with a body" do
          let(:body) { { name: "foo" } }

          subject { put(path, body.to_json, headers) }

          it "creates a new pacticipant when the pacticipant does not exist" do
            allow(PactBroker::Pacticipants::Service).to receive(:find_pacticipant_by_name).and_return(nil)
            subject
            last_response.status.should == 404
          end

          context "when pacticipant exist" do
            before do
              td.create_consumer("Foo")
                .create_consumer_version("1")
                .create_consumer("Bar")
                .create_consumer_version("10")
            end

            it "updates the existing pacticipant" do
              subject
              last_response.status.should == 200
            end
          end
        end
      end

      describe "PATCH" do
        before do
          allow(PactBroker::Pacticipants::Service).to receive(:find_pacticipant_by_name).and_return(pacticpant)
        end

        let(:pacticpant) { nil }
        let(:path) { "/pacticipants/foo" }
        let(:headers) { {"CONTENT_TYPE" => "application/merge-patch+json"} }
        let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}

        subject { patch(path, "", headers) }

        context "with an empty body" do
          its(:status) { is_expected.to eq 201 }
        end
        context "with a body" do
          let(:body) { { name: "foo" } }

          subject { patch(path, body.to_json, headers) }

          it "creates a new pacticipant when the pacticipant does not exist" do
            expect(PactBroker::Pacticipants::Service).to receive(:create)
              .with({ name: "foo" })
            subject
          end

          context "when pacticipant exist" do
            before do
              td.create_consumer("Foo")
                .create_consumer_version("1")
                .create_consumer("Bar")
                .create_consumer_version("10")
            end

            it "updates the existing pacticipant" do
              subject
              last_response.status.should == 201
            end
          end
        end
      end
      describe "GET" do
        let(:pacticipant) { td.create_consumer("Consumer").and_return(:pacticipant) }
        let(:version) { td.use_consumer(pacticipant.name).create_consumer_version("1").and_return(:consumer_version) }
        let(:test_environment) { td.create_environment("test").and_return(:environment) }
        let(:prod_environment) { td.create_environment("prod").and_return(:environment) }
        let(:deployed_version) do
          td.use_consumer_version(version.number)
            .create_deployed_version(
              uuid: "1234", currently_deployed: true, version: version, environment_name: test_environment.name, 
              created_at: DateTime.now - 2)
            .create_deployed_version(
              uuid: "5678", currently_deployed: true, version: version, environment_name: prod_environment.name,
              created_at: DateTime.now - 1)
        end
        before do
          deployed_version
        end

        let(:path) { "/pacticipants/Consumer" }

        subject { get(path) }

        context "when the pacticipant exists" do
          it "returns a 200 OK" do
            subject
            expect(last_response.status).to eq 200
          end

          it "has deploued-environments link" do
            subject
            json_body = JSON.parse(last_response.body)
            expect(json_body["_links"]["pb:deployed-environments"]).to_not be_nil
          end
        end
      end

      describe "DELETE" do
        before do
          allow(PactBroker::Pacticipants::Service).to receive(:delete)
          allow(PactBroker::Pacticipants::Service).to receive(:find_pacticipant_by_name).and_return(pacticpant)
        end

        let(:pacticpant) { double("pacticpant") }

        subject { delete("/pacticipants/Some%20Service" ) }

        context "when the resource exists" do
          it "deletes the pacticpant by name" do
            expect(PactBroker::Pacticipants::Service).to receive(:delete).with("Some Service")
            subject
          end

          it "returns a 204 OK" do
            subject
            expect(last_response.status).to eq 204
          end
        end

        context "when the resource doesn't exist" do

          let(:pacticpant) { nil }

          it "returns a 404 Not Found" do
            subject
            expect(last_response.status).to eq 404
          end
        end

        context "when an error occurs" do
          before do
            allow(PactBroker::Pacticipants::Service).to receive(:delete).and_raise("An error")
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
    end
  end
end
