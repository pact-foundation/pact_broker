require 'pact_broker/api/decorators/publish_contracts_results_decorator'
require 'pact_broker/contracts/contracts_publication_results'
require 'pact_broker/contracts/notice'

module PactBroker
  module Api
    module Decorators
      describe PublishContractsResultsDecorator do
        describe "to_hash" do
          before do
            allow(decorator).to receive(:version_url).and_return("version_url")
            allow(decorator).to receive(:tag_url).and_return("tag_url")
            allow(decorator).to receive(:pact_url).and_return("pact_url")
            allow(decorator).to receive(:pacticipant_url).and_return("pacticipant_url")
            allow(version).to receive(:pacticipant).and_return(pacticipant)
            allow(tag).to receive(:version).and_return(version)
          end

          let(:results) do
            PactBroker::Contracts::ContractsPublicationResults.from_hash(
              notices: notices,
              pacticipant: pacticipant,
              version: version,
              contracts: contracts,
              tags: tags
            )
          end
          let(:contracts) { [pact] }
          let(:pact) { instance_double(PactBroker::Domain::Pact, name: "pact name") }
          let(:pacticipant) { PactBroker::Domain::Pacticipant.new(name: "Foo" ) }
          let(:tags) { [tag]}
          let(:tag) { PactBroker::Domain::Tag.new(name: "main")}
          let(:version) { PactBroker::Domain::Version.new(number: "1" ) }
          let(:notices) { [PactBroker::Contracts::Notice.warning("foo") ] }
          let(:decorator_options) { { user_options: user_options } }
          let(:user_options) do
            {
              base_url: 'http://example.org'
            }
          end

          let(:decorator) { PublishContractsResultsDecorator.new(results) }

          subject { decorator.to_hash(decorator_options) }

          it {
            Approvals.verify(subject, :name => "publish_contracts_results_decorator", format: :json)
          }
        end
      end
    end
  end
end
