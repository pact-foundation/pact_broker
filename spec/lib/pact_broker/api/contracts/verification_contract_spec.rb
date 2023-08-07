require "pact_broker/api/contracts/verification_contract"
require "pact_broker/api/decorators/verification_decorator"
require "pact_broker/domain/verification"

module PactBroker
  module Api
    module Contracts
      describe VerificationContract do
        include PactBroker::Test::ApiContractSupport

        let(:verification) { PactBroker::Domain::Verification.new }
        let(:valid_params) { { success: success, providerApplicationVersion: provider_version, buildUrl: build_url } }
        let(:params) { valid_params }
        let(:success) { true }
        let(:provider_version) { "4.5.6" }
        let(:build_url) { "http://foo" }
        let(:order_versions_by_date) { false }

        subject { format_errors_the_old_way(VerificationContract.call(params)) }

        def modify hash, options
          hash.delete(options.fetch(:without))
          hash
        end

        describe "errors" do

          before do
            allow(PactBroker.configuration).to receive(:order_versions_by_date).and_return(order_versions_by_date)
          end

          context "with valid fields" do
            it { is_expected.to be_empty }
          end

          context "with no success property" do
            let(:success) { nil }

            it "has an error" do
              expect(subject[:success]).to include(match("boolean"))
            end
          end

          context "when success is a non-boolean string" do
            let(:success) { "foo" }

            it "has an error" do
              expect(subject[:success]).to include(match("boolean"))
            end
          end

          context "when buildUrl is not a URL" do
            let(:build_url) { "foo bar" }

            it "has an error" do
              expect(subject[:buildUrl]).to include(match("URL"))
            end
          end

          context "when buildUrl is nil" do
            let(:build_url) { nil }

            it { is_expected.to be_empty }
          end

          context "when the buildURL is not present" do
            let(:params) { modify valid_params, without: :buildUrl }

            it { is_expected.to be_empty }
          end

          context "when the buildURL is not stringable" do
            let(:build_url) { {} }

            it "has an error" do
              expect(subject[:buildUrl]).to include(match("string"))
            end
          end

          context "when the providerApplicationVersion is not present" do
            let(:params) { modify valid_params, without: :providerApplicationVersion }

            it "has an error" do
              expect(subject[:providerApplicationVersion]).to include(match("missing"))
            end
          end

          context "when the providerApplicationVersion is blank" do
            let(:provider_version) { " " }

            it "has an error" do
              expect(subject[:providerApplicationVersion]).to contain_exactly(match("blank"))
            end
          end

          context "when order_versions_by_date is true" do
            let(:order_versions_by_date) { true }

            context "when the providerApplicationVersion is not a semantic version" do
              let(:provider_version) { "#" }

              it { is_expected.to be_empty }
            end
          end

          context "when order_versions_by_date is false" do
            context "when the providerApplicationVersion is not a semantic version" do
              let(:provider_version) { "#" }

              it "has an error" do
                expect(subject[:providerApplicationVersion]).to include(match("#.*cannot be parsed"))
              end
            end
          end
        end
      end
    end
  end
end
