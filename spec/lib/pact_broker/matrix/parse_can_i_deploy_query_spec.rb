require 'pact_broker/matrix/parse_can_i_deploy_query'

module PactBroker
  module Matrix
    describe ParseCanIDeployQuery do
      describe ".call" do
        let(:params) do
          {
            pacticipant: "foo",
            version: "1",
            environment: "prod"
          }
        end

        subject(:result) { ParseCanIDeployQuery.call(params) }

        let(:parsed_selectors) { result.first }
        let(:parsed_options) { result.last }

        describe "parsed_options" do
          subject { parsed_options }

          its([:latestby]) { is_expected.to eq "cvp" }
          its([:latest]) { is_expected.to eq true }
          its([:ignore_selectors]) { is_expected.to eq [] }

          context "with pacticipants to ignore" do
            before do
              params[:ignore] = ["foo", "bar", {"a" => "b"}]
            end

            its([:ignore_selectors]) do
              is_expected.to eq [
                PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: "foo"),
                PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: "bar")
              ]
            end
          end
        end

        describe "parsed_selectors" do
          subject { parsed_selectors }

          it { is_expected.to eq [PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: "foo", pacticipant_version_number: "1")] }
        end
      end
    end
  end
end
