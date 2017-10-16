require 'spec_helper'
require 'pact_broker/pacticipants/find_potential_duplicate_pacticipant_names'

module PactBroker

  module Pacticipants

    describe FindPotentialDuplicatePacticipantNames do

      describe "split" do
        TEST_CASES = [
          ["a-foo-service", ["a", "foo", "service"]],
          ["a_foo_service", ["a", "foo", "service"]],
          ["FooAService", ["foo", "a", "service"]],
          ["Foo A Service", ["foo", "a", "service"]],
          ["S3 Bucket Service", ["s3", "bucket", "service"]],
          ["S3BucketService", ["s3", "bucket", "service"]],
          ["S3-Bucket-Service", ["s3", "bucket", "service"]],
          ["S3_Bucket_Service", ["s3", "bucket", "service"]],
        ]

        TEST_CASES.each do | input, output |
          it "splits #{input} into #{output.inspect}" do
            expect(FindPotentialDuplicatePacticipantNames.split(input)).to eq output
          end
        end
      end

      describe ".call" do

        subject { FindPotentialDuplicatePacticipantNames.call(new_name, existing_names) }


        TEST_CASES = [
          ["accounts", ["accounts-receivable"], []],
          ["Accounts", ["Accounts Receivable"], []],
          ["The Accounts", ["Accounts"], []],
          ["accounts", ["account-service", "account-api", "account-provider"], ["account-service", "account-api", "account-provider"]],
          ["accounts-api", ["account-service", "account-provider"], ["account-service", "account-provider"]],
          ['Contracts Service', ['Contracts Service', 'Contracts', 'Something'], []],
          ['Contracts', ['Contract Service', 'Contacts', 'Something'], ['Contract Service']],
          ['Contracts Service', ['Contract', 'Contacts', 'Something'], ['Contract']],
          ['Contract Service', ['Contracts', 'Contacts', 'Something'], ['Contracts']],
          ['Contract Service', ['contracts', 'Contacts', 'Something'], ['contracts']],
          ['ContractService', ['Contracts Service', 'Contacts', 'Something'], ['Contracts Service']],
          ['Contract Service', ['ContractsService', 'Contacts', 'Something'], ['ContractsService']],
          ['Contract_Service', ['ContractsService', 'Contracts Service', 'contracts-service', 'Contacts', 'Something'], ['ContractsService', 'Contracts Service', 'contracts-service']]
        ]

        TEST_CASES.each do | the_new_name, the_existing_names, the_expected_duplicates |
          context "when the new name is #{the_new_name} and the existing names are #{the_existing_names.inspect}" do
            let(:new_name) { the_new_name }
            let(:existing_names) { the_existing_names }
            let(:expected_duplicates) { the_expected_duplicates}

            it "returns #{the_expected_duplicates.inspect} as the potential duplicates" do
              expect(subject).to eq expected_duplicates
            end
          end
        end
      end
    end
  end
end
