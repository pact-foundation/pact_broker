require "spec_helper"
require "pact_broker/pacticipants/repository"
require "support/test_data_builder"

module PactBroker
  module Pacticipants
    describe Repository do
      describe "#create" do
        let(:repository) { Repository.new }

        subject { repository.create(name: "Foo") }

        context "when the pacticipant does not already exist" do
          before do
            td.create_pacticipant("Bar")
            allow_any_instance_of(PactBroker::Domain::Pacticipant).to receive(:generate_display_name).and_return("display_name")
          end

          let(:display_name) { "Foo" }

          subject { repository.create(name: "foo", display_name: display_name, repository_url: "url", main_branch: "main") }

          it "returns the new pacticipant" do
            expect(subject).to be_a(PactBroker::Domain::Pacticipant)
            expect(subject.name).to eq "foo"
            expect(subject.main_branch).to eq "main"
            expect(subject.repository_url).to eq "url"
            expect(subject.display_name).to eq "Foo"
          end

          context "when no display name is provided" do
            let(:display_name) { nil }

            it "generates one" do
              expect(subject.display_name).to eq "display_name"
            end
          end
        end

        context "when a race condition occurs and the pacticipant was already created by another request" do
          before do
            td.create_pacticipant("Foo", repository_url: "original")
          end

          it "does not raise an error" do
            subject
          end

          it "returns the existing pacticipant" do
            expect(subject).to be_a(PactBroker::Domain::Pacticipant)
            expect(subject.name).to eq "Foo"
            expect(subject.repository_url).to eq "original"
          end
        end
      end

      describe "replace" do
        before do
          td.create_pacticipant("Bar", main_branch: "foo", repository_namespace: "foo")
          allow_any_instance_of(PactBroker::Domain::Pacticipant).to receive(:generate_display_name).and_return("display_name")
        end

        subject { Repository.new.replace("Bar", OpenStruct.new(main_branch: "bar", repository_url: "new_url")) }

        it "does not create a new record" do
          expect { subject }.to_not change { PactBroker::Domain::Pacticipant.count }
        end

        it "replaces the pacticipant" do
          expect(subject.name).to eq "Bar"
          expect(subject.main_branch).to eq "bar"
          expect(subject.repository_namespace).to eq nil
          expect(subject.display_name).to eq "display_name"
        end
      end

      describe "delete" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
        end

        subject { Repository.new.delete(td.consumer) }

        it "deletes the integration" do
          expect { subject }.to change{ PactBroker::Integrations::Integration.count }.by(-1)
        end
      end

      describe "#find" do
        before do
          td
            .create_pacticipant("Foo")
            .create_label("in")
            .create_pacticipant("Bar")
            .create_label("in")
            .create_label("blah")
            .create_pacticipant("Wiffle")
            .create_label("out")
        end

        subject { Repository.new.find label_name: "in" }

        it "returns the pacticipants with the given label" do
          expect(subject.collect(&:name)).to eq ["Bar", "Foo"]
        end

        context "with search query" do
          subject { Repository.new.find query_string: "wif" }

          it "returns the pacticipants with the given label" do
            expect(subject.collect(&:name)).to eq ["Wiffle"]
          end
        end
      end

      describe "#find_by_name" do
        before do
          td.create_pacticipant("Foo-Bar")
        end

        subject { Repository.new.find_by_name("foo-bar") }

        context "when the name is a different case" do
          context "with case sensitivity turned on" do
            before do
              allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(true)
            end

            it "returns nil" do
              expect(subject).to be nil
            end
          end

          context "with case sensitivity turned off" do
            before do
              allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(false)
            end

            it "returns the pacticipant" do
              expect(subject).to_not be nil
              expect(subject.name).to eq "Foo-Bar"
            end
          end

          context "with case sensitivity turned off and multiple records found", skip: PactBroker::TestDatabase.mysql?  do
            # Can't be created in MySQL - duplicate record
            before do
              td.create_pacticipant("Foo-bar")
              allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(false)
            end

            it "raises an error" do
              expect { subject }.to raise_error PactBroker::Error, /Found multiple pacticipants.*foo-bar/
            end
          end

          context "with case sensitivity turned off and searching for a name with an underscore" do
            before do
              allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(false)
            end

            subject { Repository.new.find_by_name("foo_bar") }

            it { is_expected.to be nil }
          end

          context "with case sensitivity turned on and searching for a name with an underscore" do
            subject { Repository.new.find_by_name("foo_bar") }

            it { is_expected.to be nil }
          end

          context "with case sensitivity turned off no record found" do
            subject { Repository.new.find_by_name("blah") }

            it { is_expected.to be nil }
          end
        end
      end

      describe "#find_by_names" do
        before do
          td.create_pacticipant("foo")
            .create_pacticipant("bar")
            .create_pacticipant("wiffle")
        end

        subject { Repository.new.find_by_names(["foo", "bar"]) }

        it { is_expected.to contain_exactly(have_attributes(name: "foo"), have_attributes(name: "bar")) }

        context "when the names array is empty" do
          subject { Repository.new.find_by_names([]) }

          its(:size) { is_expected.to eq 0 }
        end
      end

      describe "#pacticipant_names" do
        before do
          td
            .create_pacticipant("Plants")
            .create_pacticipant("Animals")
        end

        subject { Repository.new.pacticipant_names }

        it "returns an array of pacticipant names" do
          expect(subject).to eq ["Animals", "Plants"]
        end

      end

      describe "#search_by_name" do
        let(:consumer_name) { "This is_a test-consumer" }
        let(:provider_name) { "and a test/provider" }

        before do
          td
            .create_consumer(consumer_name)
            .create_consumer(provider_name)
        end

        context "when there is a consumer/provider name which matches the search term" do
          it "returns the pacticipants" do
            searched_dataset =  Repository.new.search_by_name "consumer"
            expect(searched_dataset.collect(&:name)).to eq([consumer_name])

            searched_dataset =  Repository.new.search_by_name "provider"
            expect(searched_dataset.collect(&:name)).to eq([provider_name])

            searched_dataset =  Repository.new.search_by_name "test"
            expect(searched_dataset.collect(&:name)).to include(*[consumer_name, provider_name])
          end

          # SQL escape character is '_'
          it "escapes the '_' character" do
            searched_dataset =  Repository.new.search_by_name "is_a"
            expect(searched_dataset.collect(&:name)).to eq([consumer_name])
          end

          it "searches case insentively" do
            searched_dataset =  Repository.new.search_by_name "TEST"
            expect(searched_dataset.collect(&:name)).to include(*[consumer_name, provider_name])
          end
        end

        context "when there is NO consumer/provider name which matches the search term" do
          it "returns empty dataset" do
            searched_dataset =  Repository.new.search_by_name "this_will_not_yield_any_result"
            expect(searched_dataset.count).to eq(0)
          end
        end
      end
    end
  end
end
