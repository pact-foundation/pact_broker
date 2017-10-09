require 'pact_broker/matrix/repository'

module PactBroker
  module Matrix
    describe Repository do
      describe "#find" do
        before do
          TestDataBuilder.new
            .create_pact_with_hierarchy("Consumer", "1.2.3", "Provider")
            .create_verification(provider_version: "6.7.8")
            .revise_pact
            .create_verification(provider_version: "4.5.6")
            .create_consumer_version("2.0.0")
            .create_pact
        end

        subject { Repository.new.find "Consumer", "Provider" }

        it "returns the latest revision of each pact in reverse consumer_version_order" do
          expect(subject.count).to eq 2
          expect(subject[0][:consumer_version_number]).to eq "2.0.0"
          expect(subject[1][:consumer_version_number]).to eq "1.2.3"
        end

        it "returns the latest verification for the pact version" do
          expect(subject[1][:provider_version_number]).to eq "4.5.6"
        end

        it "doesn't matter which way you order the pacticipant names" do
          expect(subject).to eq(Repository.new.find "Provider", "Consumer")
        end
      end

      describe "#find_compatible_pacticipant_versions" do
        let(:td) { TestDataBuilder.new }

        context "when compatible versions can be found" do
          before do
            td.create_pact_with_hierarchy("A", "1", "B")
              .create_verification(provider_version: '1')
              .create_verification(provider_version: '2', number: 2)
              .use_consumer("B")
              .use_consumer_version("1")
              .create_provider("C")
              .create_pact
              .create_verification(provider_version: '1', success: true)
              .use_consumer_version("2")
              .create_pact
              .create_verification(provider_version: '2', success: true)
              .create_verification(provider_version: '3', number: 2, success: true)
          end

          subject { Repository.new.find_compatible_pacticipant_versions("A" => "1", "B" => "2", "C" => "2") }

          it "returns matrix lines for each compatible version pair" do
            expect(subject.first[:consumer_name]).to eq "A"
            expect(subject.first[:consumer_version_number]).to eq "1"
            expect(subject.first[:provider_name]).to eq "B"
            expect(subject.first[:provider_version_number]).to eq "2"
            expect(subject.first[:number]).to eq 2

            expect(subject.last[:consumer_name]).to eq "B"
            expect(subject.last[:consumer_version_number]).to eq "2"
            expect(subject.last[:provider_name]).to eq "C"
            expect(subject.last[:provider_version_number]).to eq "2"
            expect(subject.last[:number]).to eq 1

            expect(subject.size).to eq 2
          end
        end

        context "when there is more than one compatible version pair" do
          before do
            td.create_pact_with_hierarchy("X", "1", "Y")
              .create_verification(provider_version: "1")
              .create_verification(provider_version: "1", number: 2)
          end
          subject { Repository.new.find_compatible_pacticipant_versions("X" => "1", "Y" => "1") }

          it "returns the last line" do
            expect(subject.size).to eq 1
            expect(subject.first[:number]).to eq 2
          end
        end

        context "when there is more than one compatible verison pair and the last one is a failure" do
          before do
            td.create_pact_with_hierarchy("X", "1", "Y")
              .create_verification(provider_version: "1")
              .create_verification(provider_version: "1", number: 2, success: false)
          end

          subject { Repository.new.find_compatible_pacticipant_versions("X" => "1", "Y" => "1") }

          it "does not return a matrix line" do
            expect(subject.size).to eq 0
          end
        end

        context "when a pact is verified, but then revised and the new revision is not verified" do
          before do
            td.create_pact_with_hierarchy("X", "1", "Y")
              .create_verification(provider_version: "1")
              .revise_pact
          end

          subject { Repository.new.find_compatible_pacticipant_versions("X" => "1", "Y" => "1") }

          it "does not return a matrix line" do
            expect(subject.size).to eq 0
          end
        end

        context "when the verification result is false" do
          before do
            TestDataBuilder.new
              .create_pact_with_hierarchy("D", "1", "E")
              .create_verification(provider_version: '1', success: false)
          end

          subject { Repository.new.find_compatible_pacticipant_versions("D" => "1", "E" => "1") }

          it "does not return the matrix line" do
            expect(subject.count).to eq 0
          end
        end
      end
    end
  end
end
