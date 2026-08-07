require "pact_broker/matrix/unresolved_selector"
require "pact_broker/matrix/resolved_selector"

module PactBroker
  module Matrix
    # The matrix query builders send each selector down one of two mutually
    # exclusive paths: name-only selectors filter on pacticipant_id, everything
    # else filters on the version id the resolver already found. Two separate
    # predicates make that decision, in two different classes. If they ever
    # disagree, a selector reaches the version-id branch carrying a nil id,
    # Sequel renders `IN (NULL)`, and the query returns an empty result rather
    # than raising — a wrong answer, silently.
    describe "name-only selector predicate equivalence" do
      # Every key that means "this selector is about more than a pacticipant".
      SELECTOR_PREDICATE_EQUIVALENCE_NON_NAME_KEYS = [
        :pacticipant_version_number,
        :latest,
        :tag,
        :branch,
        :environment_name,
        :main_branch,
        :max_age
      ].freeze

      def resolved_for(unresolved)
        ResolvedSelector.new(pacticipant_name: unresolved[:pacticipant_name], original_selector: unresolved)
      end

      it "agrees when only the pacticipant name is set" do
        unresolved = UnresolvedSelector.new(pacticipant_name: "Foo")

        expect(unresolved.all_for_pacticipant?).to be true
        expect(resolved_for(unresolved).only_pacticipant_name_specified?).to be true
      end

      SELECTOR_PREDICATE_EQUIVALENCE_NON_NAME_KEYS.each do | key |
        it "agrees when #{key} is also set" do
          unresolved = UnresolvedSelector.new(pacticipant_name: "Foo", key => "value")

          expect(unresolved.all_for_pacticipant?).to be false
          expect(resolved_for(unresolved).only_pacticipant_name_specified?).to be false
        end
      end

      # all_for_pacticipant? enumerates its keys explicitly, so a selector
      # attribute added to UnresolvedSelector without also being added there
      # would make the two predicates disagree. This example fails the moment
      # a new attribute is added to the class, which then forces the key into
      # the per-key examples above where both predicates are exercised.
      it "covers every selector attribute UnresolvedSelector defines" do
        attributes = UnresolvedSelector
          .instance_methods(false)
          .grep(/\A[a-z_]+=\z/)
          .collect { |writer| writer.to_s.chomp("=").to_sym }

        expect(attributes).to match_array(
          SELECTOR_PREDICATE_EQUIVALENCE_NON_NAME_KEYS + [:pacticipant_name]
        )
      end
    end
  end
end
