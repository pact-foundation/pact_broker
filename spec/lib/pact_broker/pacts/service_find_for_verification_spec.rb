require 'spec_helper'
require 'pact_broker/pacts/service'
require 'pact_broker/pacts/pact_params'

module PactBroker
  module Pacts
    describe Service do
      let(:td) { TestDataBuilder.new }

      describe "find_for_verification" do
        include_context "stubbed repositories"

        let(:head_pacts) { [pact_1, pact_2] }
        let(:head_tag_1) { "dev" }
        let(:head_tag_2) { "feat-x" }
        let(:pact_version_sha_1) { "1" }
        let(:pact_version_sha_2) { "2" }
        let(:domain_pact_1) { double('pact1', pending?: true) }
        let(:domain_pact_2) { double('pact2', pending?: true) }

        let(:pact_1) do
          double("HeadPact",
            head_tag: head_tag_1,
            pact_version_sha: pact_version_sha_1,
            pact: domain_pact_1
          )
        end

        let(:pact_2) do
          double("HeadPact",
            head_tag: head_tag_2,
            pact_version_sha: pact_version_sha_2,
            pact: domain_pact_2
          )
        end

        let(:provider_name) { "Bar" }
        let(:provider_version_tags) { [] }
        let(:provider_version_branch) { "main" }
        let(:consumer_version_selectors) { [] }

        before do
          allow(pact_repository).to receive(:find_for_verification).and_return(head_pacts)
        end

        subject { Service.find_for_verification(provider_name, provider_version_branch, provider_version_tags, consumer_version_selectors) }
      end
    end
  end
end
