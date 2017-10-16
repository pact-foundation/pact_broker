require 'pact_broker/api/decorators/matrix_decorator'

module PactBroker
  module Api
    module Decorators
      describe MatrixPactDecorator do
        describe "to_json" do
          let(:verification_date) { DateTime.new(2017, 12, 31) }
          let(:pact_created_at) { DateTime.new(2017, 1, 1) }
          let(:line_1) do
            {
              consumer_name: "Consumer",
              consumer_version_number: "1.0.0",
              pact_version_sha: "1234",
              pact_created_at: pact_created_at,
              provider_version_number: "4.5.6",
              provider_name: "Provider",
              success: true,
              number: 1,
              build_url: nil,
              verification_executed_at: verification_date
            }
          end

          let(:line_2) do
            {
              consumer_name: "Consumer",
              consumer_version_number: "1.0.0",
              pact_version_sha: "1234",
              pact_created_at: pact_created_at,
              provider_version_number: nil,
              provider_name: "Provider",
              success: nil,
              number: nil,
              build_url: nil,
              verification_executed_at: nil
            }
          end

          let(:consumer_hash) do
            {
              name: 'Consumer',
              _links: {
                self: {
                  href: 'http://example.org/pacticipants/Consumer'
                }
              },
              version: {
                number: '1.0.0',
                _links: {
                  self: {
                    href: 'http://example.org/pacticipants/Consumer/versions/1.0.0'
                  }
                }
              }
            }
          end

          let(:provider_hash) do
            {
              name: 'Provider',
              _links: {
                self: {
                  href: 'http://example.org/pacticipants/Provider'
                }
              },
              version: {
                number: '4.5.6'
              }
            }
          end

          let(:verification_hash) do
            {
              success: true,
              verifiedAt: "2017-12-31T00:00:00+00:00",
              _links: {
                self: {
                  href: "http://example.org/pacts/provider/Provider/consumer/Consumer/pact-version/1234/verification-results/1"
                }
              }
            }
          end

          let(:pact_hash) do
            {
              createdAt: "2017-01-01T00:00:00+00:00",
              _links: {
                self: {
                  href: "http://example.org/pacts/provider/Provider/consumer/Consumer/version/1.0.0"
                }
              }
            }
          end

          let(:lines){ [line_1, line_2]}
          let(:json) { MatrixPactDecorator.new(lines).to_json(user_options: { base_url: 'http://example.org' }) }
          let(:parsed_json) { JSON.parse(json, symbolize_names: true) }

          it "includes the consumer details" do
            expect(parsed_json[:matrix][0][:consumer]).to eq consumer_hash
          end

          it "includes the provider details" do
            expect(parsed_json[:matrix][0][:provider]).to eq provider_hash
          end

          it "includes the verification details" do
            expect(parsed_json[:matrix][0][:verificationResult]).to eq verification_hash
          end

          it "includes the pact details" do
            expect(parsed_json[:matrix][0][:pact]).to eq pact_hash
          end

          it "includes a summary" do
            expect(parsed_json[:summary][:compatible]).to eq false
          end

          context "when the pact has not been verified" do
            let(:verification_hash) do
              nil
            end

            it "has empty provider details" do
              expect(parsed_json[:matrix][1][:provider]).to eq provider_hash.merge(version: nil)
            end

            it "has a nil verificationResult" do
              expect(parsed_json[:matrix][1][:verificationResult]).to eq verification_hash
            end
          end
        end
      end
    end
  end
end
