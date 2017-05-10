require 'spec_helper'
require 'pact_broker/versions/parse_semantic_version'

module PactBroker
  module Versions
    describe ParseSemanticVersion do

      describe ".call" do
        context "when parsing a semantic version" do

          subject { ParseSemanticVersion.call("1.2.3") }

          it "returns the version" do
            expect(subject.major).to eq 1
            expect(subject.minor).to eq 2
            expect(subject.to_s).to eq "1.2.3"
          end

          it "returns a comparable version" do
            expect(subject).to be > ParseSemanticVersion.call("1.2.2")
            expect(subject).to be == ParseSemanticVersion.call("1.2.3")
            expect(subject).to be < ParseSemanticVersion.call("1.3.1")
          end

          it "allows versions with one or two parts for backwards compatibility" do
            expect(ParseSemanticVersion.call("1")).to eq ::SemVer.new(1,0,0)
            expect(ParseSemanticVersion.call("1.2")).to eq ::SemVer.new(1,2,0)
          end

          it "returns nil when version is invalid" do
            expect(ParseSemanticVersion.call("abc")).to be_nil
          end

          it "accepts semver metadata" do
            expect(ParseSemanticVersion.call("1.2.3+abc.234")).not_to be_nil
          end
        end
      end

    end
  end
end
