require "pact_broker/matrix/integrations_repository"
require "pact_broker/matrix/integration"
require "pact_broker/matrix/selector_resolver"

module PactBroker
  module Matrix
    describe IntegrationsRepository do
      UnresolvedSelector = PactBroker::Matrix::UnresolvedSelector
      Integration = PactBroker::Matrix::Integration

      before do
        # Foo v1 -> Bar v2
        # Waffle v2 -> Bar v2
        # Foo v1 -> Frog ??
        td.create_pact_with_hierarchy("Foo", "1", "Bar")
          .create_verification(provider_version: "2")
          .create_pact_with_hierarchy("Waffle", "3", "Bar")
          .create_verification(provider_version: "2")
          .create_pact_with_hierarchy("Foo", "1", "Frog")
      end

      let(:foo) { td.find_pacticipant("Foo") }
      let(:bar) { td.find_pacticipant("Bar") }
      let(:waffle) { td.find_pacticipant("Waffle") }
      let(:frog) { td.find_pacticipant("Frog") }

      let(:resolved_selectors) { PactBroker::Matrix::SelectorResolver.resolve_specified_selectors(unresolved_selectors, []) }
      let(:infer_selectors_for_integrations) { false }

      subject { PactBroker::Matrix::IntegrationsRepository.new(PactBroker::Matrix::QuickRow).find_integrations_for_specified_selectors(resolved_selectors, infer_selectors_for_integrations) }

      context "for a provider version" do
        let(:unresolved_selectors) { [UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "2")] }

        it do
          is_expected.to eq [
            Integration.new(foo.id, foo.name, bar.id, bar.name, false),
            Integration.new(waffle.id, waffle.name, bar.id, bar.name, false)
          ]
        end

        context "when inferring other integrations" do
          let(:infer_selectors_for_integrations) { true }

          it do
            is_expected.to eq [
              Integration.new(foo.id, foo.name, bar.id, bar.name, false),
              Integration.new(waffle.id, waffle.name, bar.id, bar.name, false)
            ]
          end
        end
      end

      context "for a provider" do
        let(:unresolved_selectors) { [UnresolvedSelector.new(pacticipant_name: "Bar")] }

        it do
          is_expected.to eq [
            Integration.new(foo.id, foo.name, bar.id, bar.name, false),
            Integration.new(waffle.id, waffle.name, bar.id, bar.name, false)
          ]
        end

        context "when inferring other integrations" do
          let(:infer_selectors_for_integrations) { true }

          it do
            is_expected.to eq [
              Integration.new(foo.id, foo.name, bar.id, bar.name, false),
              Integration.new(waffle.id, waffle.name, bar.id, bar.name, false)
            ]
          end
        end
      end

      context "for a consumer version" do
        let(:unresolved_selectors) { [UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1")] }

        it do
          is_expected.to eq [
            Integration.new(foo.id, foo.name, bar.id, bar.name, true),
            Integration.new(foo.id, foo.name, frog.id, frog.name, true),
          ]
        end

        context "when inferring other integrations" do
          let(:infer_selectors_for_integrations) { true }

          it do
            is_expected.to eq [
              Integration.new(foo.id, foo.name, bar.id, bar.name, true),
              Integration.new(foo.id, foo.name, frog.id, frog.name, true),
            ]
          end
        end
      end

      context "for a consumer" do
        let(:unresolved_selectors) { [UnresolvedSelector.new(pacticipant_name: "Foo")] }

        it do
          is_expected.to eq [
            Integration.new(foo.id, foo.name, bar.id, bar.name, true),
            Integration.new(foo.id, foo.name, frog.id, frog.name, true),
          ]
        end

        context "when inferring other integrations" do
          let(:infer_selectors_for_integrations) { true }

          it do
            is_expected.to eq [
              Integration.new(foo.id, foo.name, bar.id, bar.name, true),
              Integration.new(foo.id, foo.name, frog.id, frog.name, true),
            ]
          end
        end
      end

      context "with multiple selectors with versions" do
        let(:unresolved_selectors) do
          [
            UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "2"),
            UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1")
          ]
        end

        it do
          is_expected.to eq [
            Integration.new(foo.id, foo.name, bar.id, bar.name, true)
          ]
        end

        context "when inferring other integrations" do
          let(:infer_selectors_for_integrations) { true }

          it do
            is_expected.to eq [
              Integration.new(foo.id, foo.name, bar.id, bar.name, true),
              Integration.new(foo.id, foo.name, frog.id, frog.name, true),
              Integration.new(waffle.id, waffle.name, bar.id, bar.name, false)
            ]
          end
        end
      end

      context "when there are 2 applications versions that each have a contract with the other" do
        before do
          td.create_pact_with_hierarchy("Bar", "2", "Foo")
            .create_verification(provider_version: "1")
        end

        let(:unresolved_selectors) do
          [
            UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "2"),
            UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1")
          ]
        end

        it do
          is_expected.to eq [
            Integration.new(foo.id, foo.name, bar.id, bar.name, true),
            Integration.new(bar.id, bar.name, foo.id, foo.name, true)
          ]
        end

        context "when inferring other integrations" do
          let(:infer_selectors_for_integrations) { true }

          it do
            is_expected.to eq [
              Integration.new(bar.id, bar.name, foo.id, foo.name, true),
              Integration.new(foo.id, foo.name, bar.id, bar.name, true),
              Integration.new(foo.id, foo.name, frog.id, frog.name, true),
              Integration.new(waffle.id, waffle.name, bar.id, bar.name, false)
            ]
          end
        end
      end
    end
  end
end
