require "pact_broker/pacts/repository"
require "pact_broker/pacts/service"
require "pact_broker/versions/branch_version_repository"

# The semantics of `fallbackTag`, one row per case. The rules come from the
# consumer version selector docs:
#
#   R1 Per consumer. Each consumer in scope gets the latest pact with `tag`.
#      Failing that, it gets the latest pact with `fallbackTag`. Failing that, nothing.
#   R2 Independent selectors. What a selector selects depends only on that selector
#      and the data. The result is the union across selectors, merged per pact.
#   R3 "Has a pact for the tag" means a pact with this provider.
#   R4 An explicitly selected pact is never WIP.
#   R5 A fallback pact is pending by the provider's usual pending rules.
#
# Pacts with the same content for one consumer merge into one, under the latest
# version, carrying every selector that chose them.
#
# Each pact entry is [consumer, version, tags, options]. The options are
# `provider` (default "Bar"), `branch`, and `content`; a consumer's pacts that
# share a `content` key share their content. Each expected entry is
# [consumer, version, labels]. A label is the tag that selected the pact,
# "tag->fallbackTag" when the fallback selected it, or "branch:name".
#
# `fallbackTag` without `latest: true` is rejected by the request contract; see
# pacts_for_verification_json_query_schema_spec.rb.
module PactBroker
  module Pacts
    describe "fallbackTag semantics" do
      def self.sel(tag, fallback = nil, consumer: nil, latest: true)
        Selector.new({ tag: tag, fallback_tag: fallback, latest: latest, consumer: consumer }.compact)
      end

      # MARK: Table

      rows = [
        { id: "F1", rule: "R1", title: "the consumer has the tag",
          pacts: [["Foo", "1", %w[master]], ["Foo", "2", %w[feat-x]]],
          selectors: [sel("feat-x", "master")],
          expected: [["Foo", "2", %w[feat-x]]] },

        { id: "F2", rule: "R1", title: "the consumer lacks the tag but has the fallback",
          pacts: [["Foo", "1", %w[master]]],
          selectors: [sel("feat-x", "master")],
          expected: [["Foo", "1", %w[feat-x->master]]] },

        { id: "F3", rule: "R1", title: "the consumer has neither tag",
          pacts: [["Foo", "1", %w[develop]]],
          selectors: [sel("feat-x", "master")],
          expected: [] },

        { id: "F4", rule: "R1", title: "one consumer has the tag, another only the fallback",
          pacts: [["Foo", "1", %w[master]], ["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[master]]],
          selectors: [sel("feat-x", "master")],
          expected: [["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[feat-x->master]]] },

        { id: "F5", rule: "R1", title: "every consumer has the tag",
          pacts: [["Foo", "1", %w[master]], ["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[master]], ["Foo2", "4", %w[feat-x]]],
          selectors: [sel("feat-x", "master")],
          expected: [["Foo", "2", %w[feat-x]], ["Foo2", "4", %w[feat-x]]] },

        { id: "F6", rule: "R1", title: "one consumer has the tag, another has neither",
          pacts: [["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[develop]]],
          selectors: [sel("feat-x", "master")],
          expected: [["Foo", "2", %w[feat-x]]] },

        { id: "F7", rule: "R1", title: "the latest tag pact wins over an older one",
          pacts: [["Foo", "1", %w[master]], ["Foo", "2", %w[feat-x]], ["Foo", "5", %w[feat-x]]],
          selectors: [sel("feat-x", "master")],
          expected: [["Foo", "5", %w[feat-x]]] },

        { id: "F8", rule: "R1", title: "the latest fallback pact wins over an older one",
          pacts: [["Foo", "1", %w[master]], ["Foo", "6", %w[master]]],
          selectors: [sel("feat-x", "master")],
          expected: [["Foo", "6", %w[feat-x->master]]] },

        { id: "F9", rule: "R1", title: "one version carries both the tag and the fallback",
          pacts: [["Foo", "2", %w[feat-x master]]],
          selectors: [sel("feat-x", "master")],
          expected: [["Foo", "2", %w[feat-x]]] },

        { id: "C1", rule: "R1", title: "a scoped selector's consumer has only the fallback while another consumer has the tag",
          pacts: [["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[master]]],
          selectors: [sel("feat-x", "master", consumer: "Foo2")],
          expected: [["Foo2", "3", %w[feat-x->master]]] },

        { id: "C2", rule: "R1", title: "a scoped selector's consumer has the tag while another consumer has only the fallback",
          pacts: [["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[master]]],
          selectors: [sel("feat-x", "master", consumer: "Foo")],
          expected: [["Foo", "2", %w[feat-x]]] },

        { id: "C3", rule: "R1", title: "a scoped selector's consumer has neither tag while another consumer has the tag",
          pacts: [["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[develop]]],
          selectors: [sel("feat-x", "master", consumer: "Foo2")],
          expected: [] },

        { id: "I1", rule: "R2", title: "a plain tag selector selects another consumer's tag pact beside a fallback selector scoped to Foo2",
          pacts: [["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[master]]],
          selectors: [sel("feat-x"), sel("feat-x", "master", consumer: "Foo2")],
          expected: [["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[feat-x->master]]] },

        { id: "I2", rule: "R2", title: "two fallback selectors with different tags fall back for each other's consumer",
          pacts: [["Foo", "1", %w[master]], ["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[master]], ["Foo2", "4", %w[feat-y]]],
          selectors: [sel("feat-x", "master"), sel("feat-y", "master")],
          expected: [
            ["Foo", "1", %w[feat-y->master]], ["Foo", "2", %w[feat-x]],
            ["Foo2", "3", %w[feat-x->master]], ["Foo2", "4", %w[feat-y]]
          ] },

        { id: "I3", rule: "R2", title: "two fallback selectors share a tag but have different fallbacks",
          pacts: [["Foo2", "3", %w[master]], ["Foo2", "7", %w[develop]]],
          selectors: [sel("feat-x", "master"), sel("feat-x", "develop")],
          expected: [["Foo2", "3", %w[feat-x->master]], ["Foo2", "7", %w[feat-x->develop]]] },

        { id: "M1", rule: "R2", title: "a plain selector also selects the fallback pact, so the two merge",
          pacts: [["Foo", "1", %w[master]], ["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[master]]],
          selectors: [sel("feat-x", "master"), sel("master")],
          expected: [["Foo", "1", %w[master]], ["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[feat-x->master master]]] },

        { id: "M2", rule: "R2", title: "a branch selector also selects the fallback pact, so the two merge",
          pacts: [["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[master], { branch: "main" }]],
          selectors: [sel("feat-x", "master"), Selector.latest_for_branch("main")],
          expected: [["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[branch:main feat-x->master]]] },

        { id: "D1", rule: "R2", title: "a consumer's fallback pact has the same content as its tag pact, so the two merge",
          pacts: [
            ["Foo", "1", %w[master], { content: "same" }], ["Foo", "2", %w[feat-x], { content: "same" }],
            ["Foo2", "3", %w[master]], ["Foo2", "4", %w[feat-y]]
          ],
          selectors: [sel("feat-x", "master"), sel("feat-y", "master")],
          expected: [["Foo", "2", %w[feat-x feat-y->master]], ["Foo2", "3", %w[feat-x->master]], ["Foo2", "4", %w[feat-y]]] },

        { id: "P1", rule: "R3", title: "a consumer's tag pact belongs to another provider",
          pacts: [["Foo2", "3", %w[master]], ["Foo2", "4", %w[feat-x], { provider: "Baz" }]],
          selectors: [sel("feat-x", "master")],
          expected: [["Foo2", "3", %w[feat-x->master]]] },
      ]

      # MARK: Runner

      def create_pacts(pacts)
        pacts.each do | consumer, version, tags, options = {} |
          provider = options.fetch(:provider, "Bar")
          td.create_pact_with_hierarchy(consumer, version, provider, pact_content(consumer, provider, options[:content]))
          tags.each { | tag | td.create_consumer_version_tag(tag) }
          PactBroker::Versions::BranchVersionRepository.new.add_branch(td.consumer_version, options[:branch]) if options[:branch]
        end
      end

      def pact_content(consumer, provider, content_key)
        return nil unless content_key
        { consumer: { name: consumer }, provider: { name: provider }, interactions: [], content: content_key }.to_json
      end

      def label(selector)
        if selector.branch
          "branch:#{selector.branch}"
        elsif selector.fallback_tag
          "#{selector.tag}->#{selector.fallback_tag}"
        else
          selector.tag
        end
      end

      def describe_result(selected_pacts)
        selected_pacts
          .collect { | p | [p.consumer_name, p.consumer_version_number, p.selectors.collect { | s | label(s) }.sort] }
          .sort
      end

      rows.each do | row |
        it "#{row[:id]} (#{row[:rule]}) #{row[:title]}" do
          create_pacts(row[:pacts])
          result = Repository.new.find_for_verification("Bar", Selectors.new(*row[:selectors]))
          expect(describe_result(result)).to eq row[:expected].sort
        end
      end

      # MARK: WIP and pending

      # Each entry is [consumer, version, wip, pending].
      def find_for_verification(provider_branch: nil, provider_tags: [], include_wip: false)
        options = { include_pending_status: true }
        options[:include_wip_pacts_since] = Date.today - 30 if include_wip
        Service.find_for_verification("Bar", provider_branch, provider_tags, Selectors.new(sel("feat-x", "master")), options)
          .collect { | p | [p.consumer_name, p.consumer_version_number, p.wip, p.pending] }
          .sort
      end

      describe "W1 (R4) with a provider tag, the fallback pact is explicitly selected, so it is not WIP" do
        before do
          create_pacts([["Foo", "1", %w[master]], ["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[master]]])
        end

        it "returns Foo2's fallback pact as pending, and only Foo's unselected master pact as WIP" do
          expect(find_for_verification(provider_tags: ["feat-x"], include_wip: true)).to eq [
            ["Foo", "1", true, true], ["Foo", "2", false, true], ["Foo2", "3", false, true]
          ]
        end
      end

      describe "W2 (R5) with a provider tag, the fallback pact is not pending once that tag has verified it" do
        before do
          create_pacts([["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[master]]])
          td.create_verification(provider_version: "1", tag_names: ["feat-x"])
        end

        it "returns Foo2's fallback pact as not pending" do
          expect(find_for_verification(provider_tags: ["feat-x"])).to eq [["Foo", "2", false, true], ["Foo2", "3", false, false]]
        end
      end

      describe "W3 (R4) with a provider branch, the fallback pact is explicitly selected, so it is not WIP" do
        before do
          create_pacts([["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[master]]])
        end

        it "returns Foo2's fallback pact as pending and not WIP" do
          expect(find_for_verification(provider_branch: "feat-x", include_wip: true)).to eq [
            ["Foo", "2", false, true], ["Foo2", "3", false, true]
          ]
        end
      end

      describe "W4 (R5) with a provider branch, the fallback pact is not pending once that branch has verified it" do
        before do
          create_pacts([["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[master]]])
          td.create_verification(provider_version: "1", branch: "feat-x")
        end

        it "returns Foo2's fallback pact as not pending" do
          expect(find_for_verification(provider_branch: "feat-x")).to eq [["Foo", "2", false, true], ["Foo2", "3", false, false]]
        end
      end

      def sel(*args, **kwargs) = self.class.sel(*args, **kwargs)
    end
  end
end
