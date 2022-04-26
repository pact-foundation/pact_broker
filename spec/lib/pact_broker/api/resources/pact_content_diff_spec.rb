require "pact_broker/api/resources/pact_content_diff"

module PactBroker
  module Api
    module Resources
      describe PactContentDiff do
        include_context "stubbed services"

        before do
          allow(pact_service).to receive(:find_pact).and_return(pact)
          allow(PactBroker::Pacts::Diff).to receive(:new).and_return(diff)
        end

        let(:pact) { double("pact") }
        let(:diff) { instance_double("PactBroker::Pacts::Diff", process: diff_content) }
        let(:diff_content) { "diff_content" }
        let(:path) { "/pacts/provider/Provider/consumer/Consumer/version/3/diff/previous-distinct" }
        let(:last_response_body) { subject.body }

        subject { get(path) }

        its(:status) { is_expected.to eq 200 }
        its(:body) { is_expected.to eq "diff_content" }

        context "when the diff takes too long to generate" do
          before do
            allow(diff).to receive(:process).and_raise(Timeout::Error)
          end

          its(:status) { is_expected.to eq 408 }
          its(:body) { is_expected.to eq "" }
        end
      end
    end
  end
end
