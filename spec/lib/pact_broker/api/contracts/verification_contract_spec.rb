require 'pact_broker/api/contracts/verification_contract'
require 'pact_broker/api/decorators/verification_decorator'
require 'pact_broker/domain/verification'

module PactBroker
  module Api
    module Contracts
      describe VerificationContract do

        subject { VerificationContract.new(verification) }
        let(:verification) { PactBroker::Domain::Verification.new }
        let(:valid_params) { {success: success, providerApplicationVersion: provider_version, buildUrl: build_url} }
        let(:params) { valid_params }


        let(:success) { true }
        let(:provider_version) { "4.5.6" }
        let(:build_url) { 'http://foo' }

        def modify hash, options
          hash.delete(options.fetch(:without))
          hash
        end

        describe "errors" do

          before do
            subject.validate(params)
          end

          context "with valid fields" do
            its(:errors) { is_expected.to be_empty }
          end

          context "with no success property" do
            let(:success) { nil }

            it "has an error" do
              expect(subject.errors[:success]).to include(match("blank"))
            end
          end

          context "when success is a non-boolean string" do
            let(:success) { "foo" }
            it "has an error" do
              expect(subject.errors[:success]).to include(match("boolean"))
            end
          end

          context "when buildUrl is not a URL" do
            let(:build_url) { "foo bar" }
            it "has an error" do
              expect(subject.errors[:build_url]).to include(match("URL"))
            end
          end

          context "when buildUrl is nil" do
            let(:build_url) { nil }
            its(:errors) { is_expected.to be_empty }
          end

          context "when the buildURL is not present" do
            let(:params) { modify valid_params, without: :buildUrl }
            its(:errors) { is_expected.to be_empty }
          end

          context "when the buildURL is not stringable" do
            let(:build_url) { {} }

            it "has an error" do
              expect(subject.errors[:build_url]).to include(match("URL"))
            end
          end

          context "when the providerApplicationVersion is not present" do
            let(:params) { modify valid_params, without: :providerApplicationVersion }
            it "has an error" do
              expect(subject.errors[:provider_version]).to include(match("can't be blank"))
            end
          end

          context "when the providerApplicationVersion is blank" do
            let(:provider_version) { " " }
            it "has an error" do
              expect(subject.errors[:provider_version]).to include(match("can't be blank"))
            end
          end

          context "when the providerApplicationVersion is not a semantic version" do
            let(:provider_version) { "#" }
            it "has an error" do
              expect(subject.errors[:provider_version]).to include(match("#.*cannot be parsed"))
            end
          end
        end
      end
    end
  end
end
