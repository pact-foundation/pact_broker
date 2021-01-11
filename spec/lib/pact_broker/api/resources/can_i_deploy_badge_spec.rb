require 'pact_broker/api/resources/can_i_deploy_badge'

module PactBroker
  module Api
    module Resources
      describe CanIDeployBadge do
        before do
          allow_any_instance_of(described_class).to receive(:badge_service).and_return(badge_service)
          allow_any_instance_of(described_class).to receive(:matrix_service).and_return(matrix_service)
          allow_any_instance_of(described_class).to receive(:pacticipant_service).and_return(pacticipant_service)
          allow_any_instance_of(described_class).to receive(:version_service).and_return(version_service)
          allow(badge_service).to receive(:can_i_deploy_badge_url).and_return("http://badge")
          allow(badge_service).to receive(:error_badge_url).and_return("http://error")
          allow(matrix_service).to receive(:find).and_return(results)
          allow(pacticipant_service).to receive(:find_pacticipant_by_name).and_return(pacticipant)
          allow(version_service).to receive(:find_by_pacticipant_name_and_latest_tag).and_return(version)
          allow(PactBroker.configuration).to receive(:show_backtrace_in_error_response?).and_return(false)
          allow(PactBroker::Errors).to receive(:generate_error_reference).and_return("abcd")
        end

        let(:pacticipant_service) { class_double("PactBroker::Pacticipant::Service").as_stubbed_const }
        let(:badge_service) { class_double("PactBroker::Badges::Service").as_stubbed_const }
        let(:matrix_service) { class_double("PactBroker::Matrix::Service").as_stubbed_const }
        let(:version_service) { class_double("PactBroker::Version::Service").as_stubbed_const }
        let(:results) { double('results', deployable?: true) }
        let(:pacticipant) { double('pacticipant') }
        let(:version) { double('version') }

        let(:path) { "/pacticipants/Foo/latest-version/main/can-i-deploy/to/prod/badge"}

        subject { get(path) }

        context "when the pacticipant exists" do
          it "returns a redirect to the badge" do
            expect(badge_service).to receive(:can_i_deploy_badge_url).with("main", "prod", nil, true)
            expect(subject.status).to eq 307
          end
        end

        context "when the pacticipant does not exist" do
          let(:pacticipant) { nil }

          it "returns a redirect to a 'not found' badge" do
            expect(badge_service).to receive(:error_badge_url).with("Foo", "not found")
            expect(subject.status).to eq 307
          end
        end

        context "when the version does not exist" do
          let(:version) { nil }

          it "returns a redirect to a 'not found' badge" do
            expect(badge_service).to receive(:error_badge_url).with("version", "not found")
            expect(subject.status).to eq 307
          end
        end

        context "with a custom label" do
          subject { get(path, label: "some custom label") }

          it "returns a redirect to a badge with a custom label" do
            expect(badge_service).to receive(:can_i_deploy_badge_url).with("main", "prod", "some custom label", true)
            subject
          end
        end

        context "when there is an error" do
          before do
            allow(matrix_service).to receive(:find).and_raise("foo error")
          end

          it "returns a redirect to a badge with an error message" do
            expect(badge_service).to receive(:error_badge_url).with("error", "reference: abcd")
            expect(subject.status).to eq 307
          end
        end
      end
    end
  end
end
