require "pact_broker/deployments/environment_service"

module PactBroker
  module Deployments
    describe EnvironmentService do
      describe ".create" do
        let(:environment) do
          Environment.new(
            name: "foo",
            display_name: display_name,
            production: false
          )
        end

        let(:display_name) { "Foo" }

        subject { EnvironmentService.create("1234", environment) }

        it "creates the environment" do
          subject
          expect(subject.name).to eq "foo"
          expect(subject.display_name).to eq "Foo"
          expect(subject.production).to eq false
        end

        context "when the display name is blank or not set" do
          let(:display_name) { " " }

          it "generates a display name" do
            expect(PactBroker::Pacticipants::GenerateDisplayName).to receive(:call).with("foo").and_return("Display Name")
            expect(subject.display_name).to eq "Display Name"
          end
        end
      end
    end
  end
end
