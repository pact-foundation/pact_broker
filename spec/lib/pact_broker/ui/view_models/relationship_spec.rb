require 'spec_helper'
require 'pact_broker/ui/view_models/relationship'

module PactBroker
  module UI
    module ViewModels
      describe Relationship do

        let(:consumer) { instance_double("PactBroker::Models::Pacticipant", name: 'consumer_name')}
        let(:provider) { instance_double("PactBroker::Models::Pacticipant", name: 'provider_name')}
        let(:relationship) { PactBroker::Models::Relationship.new(consumer, provider)}

        subject { Relationship.new(relationship) }

        its(:consumer_name) { should eq 'consumer_name'}
        its(:provider_name) { should eq 'provider_name'}
        its(:latest_pact_url) { should eq "/pact/provider/provider_name/consumer/consumer_name/latest" }

        describe "<=>" do

          xit "sorts by consumer name then provider name" do

          end
        end

      end
    end
  end
end