require "pact_broker/matrix/selector_resolver"
require "pact_broker/matrix/unresolved_selector"

module PactBroker
  module Matrix
    describe SelectorResolver do
      describe ".resolve_specified_selectors" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
        end

        def resolve(attributes)
          SelectorResolver.resolve_specified_selectors([UnresolvedSelector.new(attributes)], [])
        end

        context "when use_case_sensitive_resource_names is true" do
          before do
            allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(true)
          end

          it "does not resolve a pacticipant name that differs only in case" do
            resolved = resolve(pacticipant_name: "foo", pacticipant_version_number: "1")

            expect(resolved.first[:pacticipant_id]).to eq ResolvedSelector::NULL_PACTICIPANT_ID
          end
        end

        context "when use_case_sensitive_resource_names is false" do
          before do
            allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(false)
          end

          it "resolves a pacticipant name that differs only in case to the correct pacticipant and version" do
            expected = resolve(pacticipant_name: "Foo", pacticipant_version_number: "1").first

            resolved = resolve(pacticipant_name: "foo", pacticipant_version_number: "1").first

            expect(resolved[:pacticipant_id]).to eq expected[:pacticipant_id]
            expect(resolved[:pacticipant_id]).to_not be_nil
            expect(resolved[:pacticipant_version_id]).to eq expected[:pacticipant_version_id]
            expect(resolved[:pacticipant_version_id]).to_not be_nil
          end

          context "when two pacticipant names differ only in case" do
            before do
              td.create_pacticipant("foo")
            end

            it "raises rather than resolving to an arbitrary one of them" do
              expect { resolve(pacticipant_name: "Foo", pacticipant_version_number: "1") }
                .to raise_error PactBroker::Error, /multiple pacticipants.*Foo/
            end
          end
        end
      end
    end
  end
end
