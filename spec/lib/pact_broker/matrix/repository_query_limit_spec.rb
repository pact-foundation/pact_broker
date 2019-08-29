require 'pact_broker/matrix/repository'

module PactBroker
  module Matrix
    describe Repository do
      # See https://github.com/pact-foundation/pact_broker-client/issues/53
      # The problem occurs when a pact has so many verifications for the same provider
      # version that relevant rows do get returned in the result set because the specified limit
      # causes them to be truncated.
      # The most elegant solution is to create views have the data already grouped by
      # consumer version/provider version, consumer version/provider, and consumer/provider,
      # however, I don't have the time to work out how to make that view query efficient - I suspect
      # it will require lots of full table scans, as it will have to work out the latest pact revision
      # and latest verification for each pact publication and I'm not sure if it will have to do it
      # for the entire table, or whether it will apply the consumer/provider filters...
      # The quick and dirty solution is to do a pre-query to get the latest pact revision and latest
      # verifications for the pact versions before we do the matrix query.
      describe "Querying for can-i-deploy when there are more matrix rows than the specified query limit" do
        before do
          td.create_consumer("Foo")
            .create_provider("Bar")
            .create_consumer_version("1")
            .create_pact
            .create_verification(number: 1, provider_version: "2", tag_names: ['staging'])
            .create_verification(number: 2, provider_version: "2")
            .create_verification(number: 3, provider_version: "2")
            .create_verification(number: 4, provider_version: "2")
            .create_verification(number: 5, provider_version: "3")
            .create_provider("Wiffle")
            .create_pact
            .create_verification(number: 1, provider_version: "6", tag_names: ['staging'])
        end

        let(:path) { "/matrix?q[][pacticipant]=Foo&q[][version]=1&tag=staging&latestby=cvp&limit=2" }

        subject { get(path) }

        it "does not remove relevant rows from the query due to the specified limit" do
          expect(JSON.parse(subject.body)['summary']['deployable']).to be true
        end
      end
    end
  end
end
