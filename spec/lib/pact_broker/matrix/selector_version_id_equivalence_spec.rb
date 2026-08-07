require "pact_broker/matrix/selector_resolver"
require "pact_broker/matrix/unresolved_selector"
require "pact_broker/domain/version"

module PactBroker
  module Matrix
    # The matrix query builders filter on the version ids SelectorResolver
    # already found, instead of re-deriving them in SQL with
    # Version.ids_for_selectors. That is only sound if the two produce the same
    # set. Both route through Version.for_selector, so they should — this makes
    # it a test rather than an argument.
    describe "resolved selector version ids" do
      before do
        td.create_environment("production")
          .create_consumer("Foo")
          .create_consumer_version("1", branch: "main")
          .create_consumer_version_tag("prod")
          .create_deployed_version_for_consumer_version(environment_name: "production")
          .create_consumer_version("2", branch: "main")
          .create_consumer_version("3", branch: "feature")
          .create_consumer_version("4", branch: "hotfix")
      end

      def resolver_ids(unresolved_selectors)
        SelectorResolver.resolve_specified_selectors(unresolved_selectors, []).collect{ |s| s[:pacticipant_version_id] }.compact.uniq.sort
      end

      def sql_ids(unresolved_selectors)
        PactBroker::Domain::Version.ids_for_selectors(unresolved_selectors).all.collect(&:id).uniq.sort
      end

      [
        ["a version number", { pacticipant_name: "Foo", pacticipant_version_number: "1" }],
        ["the latest version", { pacticipant_name: "Foo", latest: true }],
        ["a tag", { pacticipant_name: "Foo", tag: "prod" }],
        ["the latest version on a branch", { pacticipant_name: "Foo", branch: "main", latest: true }],
        ["an environment", { pacticipant_name: "Foo", environment_name: "production" }],
        ["the main branch", { pacticipant_name: "Foo", main_branch: true }],
      ].each do | description, attributes |
        it "match the ids the SQL query derives, for a selector specifying #{description}" do
          unresolved = UnresolvedSelector.new(attributes)

          # A vacuous pass (both sides empty) would prove nothing about the
          # equivalence this spec exists to check, so rule it out explicitly.
          expect(resolver_ids([unresolved])).to_not be_empty

          expect(resolver_ids([unresolved])).to eq sql_ids([unresolved])
        end
      end

      it "match the ids the SQL query derives, for multiple selectors at once" do
        unresolved_selectors = [
          UnresolvedSelector.new(pacticipant_name: "Foo", tag: "prod"),
          UnresolvedSelector.new(pacticipant_name: "Foo", branch: "feature", latest: true)
        ]

        expect(resolver_ids(unresolved_selectors)).to_not be_empty
        expect(resolver_ids(unresolved_selectors)).to eq sql_ids(unresolved_selectors)
      end

      it "resolves the latest version on a branch to a different version than the pacticipant-wide latest" do
        branch_scoped = UnresolvedSelector.new(pacticipant_name: "Foo", branch: "feature", latest: true)
        pacticipant_wide = UnresolvedSelector.new(pacticipant_name: "Foo", latest: true)

        expect(resolver_ids([branch_scoped])).to_not eq resolver_ids([pacticipant_wide])
      end
    end
  end
end
