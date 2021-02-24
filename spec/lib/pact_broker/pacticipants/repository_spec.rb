require 'spec_helper'
require 'pact_broker/pacticipants/repository'
require 'support/test_data_builder'

module PactBroker
  module Pacticipants
    describe Repository do
      describe "#create" do
        let(:repository) { Repository.new }

        subject { repository.create(name: "Foo") }

        context "when the pacticipant does not already exist" do
          before do
            td.create_pacticipant("Bar")
          end

          subject { repository.create(name: "Foo", repository_url: "url", main_development_branches: ["main"]) }

          it "returns the new pacticipant" do
            expect(subject).to be_a(PactBroker::Domain::Pacticipant)
            expect(subject.name).to eq "Foo"
            expect(subject.main_development_branches).to eq ["main"]
            expect(subject.repository_url).to eq "url"
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

      describe "replace the pacticipant" do
        before do
          td.create_pacticipant("Bar", main_development_branches: ["foo"], repository_organization: "foo")
        end

        subject { Repository.new.replace("Bar", OpenStruct.new(main_development_branches: ["bar"], repository_url: "new_url")) }

        it "replaces" do
          expect(subject.main_development_branches).to eq ["bar"]
          expect(subject.repository_organization).to eq nil
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

      end
      describe "#find_by_name" do
        before do
          td.create_pacticipant("Foo-Bar")
        end

        subject { Repository.new.find_by_name('foo-bar') }

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

          context "with case sensitivity turned off and multiple records found", skip: DB.mysql?  do
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

            subject { Repository.new.find_by_name('foo_bar') }

            it { is_expected.to be nil }
          end

          context "with case sensitivity turned on and searching for a name with an underscore" do
            subject { Repository.new.find_by_name('foo_bar') }

            it { is_expected.to be nil }
          end

          context "with case sensitivity turned off no record found" do
            subject { Repository.new.find_by_name('blah') }

            it { is_expected.to be nil }
          end
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

      describe "#find_all_pacticipant_versions_in_reverse_order" do
        before do
          td
            .create_consumer("Foo")
            .create_consumer_version("1.2.3")
            .create_consumer_version("4.5.6")
            .create_consumer("Bar")
            .create_consumer_version("8.9.0")
        end

        subject { Repository.new.find_all_pacticipant_versions_in_reverse_order "Foo" }

        it "returns all the application versions for the given consumer" do
          expect(subject.collect(&:number)).to eq ["4.5.6", "1.2.3"]
        end

        context "with pagination options" do
          subject { Repository.new.find_all_pacticipant_versions_in_reverse_order "Foo", page_number: 1, page_size: 1 }

          it "paginates the query" do
            expect(subject.collect(&:number)).to eq ["4.5.6"]
          end
        end
      end
    end
  end
end
