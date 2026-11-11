require "pact_broker/pacts/repository"
require "pact_broker/pacts/service"
require "pact_broker/versions/branch_version_repository"

# The semantics of `fallbackBranch`, one row per case. The rules come from the
# consumer version selector docs:
#
#   R1 Per consumer. Each consumer in scope gets the pact for the latest version
#      of `branch`. Failing that, it gets the pact for the latest version of
#      `fallbackBranch`. Failing that, nothing.
#   R2 Independent selectors. What a selector selects depends only on that selector
#      and the data. The result is the union across selectors, merged per pact.
#   R3 "Has a pact for the branch" means the branch selector selects a pact with
#      this provider for that consumer.
#   R4 An explicitly selected pact is never WIP.
#   R5 A fallback pact is pending by the provider's usual pending rules.
#
# Pacts with the same content for one consumer merge into one, under the latest
# version, carrying every selector that chose them.
#
# Each pact entry is [consumer, version, branches, options]. The options are
# `provider` (default "Bar"), `tags`, and `content`; a consumer's pacts that
# share a `content` key share their content. Each expected entry is
# [consumer, version, labels]. A label is "branch:name" for a branch selector,
# "branch:name->fallback" when the fallback selected the pact, or the tag name.
#
# `fallbackBranch` without `branch`, or with `latest: false`, is rejected by the
# request contract. `matchingBranch` with `fallbackBranch` is rejected for the
# same reason.
module PactBroker
  module Pacts
    describe "fallbackBranch semantics" do
      def self.sel(branch, fallback = nil, consumer: nil)
        Selector.new({ branch: branch, fallback_branch: fallback, latest: true, consumer: consumer }.compact)
      end

      def self.tag_sel(tag, fallback = nil)
        Selector.new({ tag: tag, fallback_tag: fallback, latest: true }.compact)
      end

      # MARK: Table

      rows = [
        { id: "F1", rule: "R1", title: "the consumer has the branch",
          pacts: [["Foo", "1", %w[main]], ["Foo", "2", %w[feat-x]]],
          selectors: [sel("feat-x", "main")],
          expected: [["Foo", "2", %w[branch:feat-x]]] },

        { id: "F2", rule: "R1", title: "the consumer lacks the branch but has the fallback",
          pacts: [["Foo", "1", %w[main]]],
          selectors: [sel("feat-x", "main")],
          expected: [["Foo", "1", %w[branch:feat-x->main]]] },

        { id: "F3", rule: "R1", title: "the consumer has neither branch",
          pacts: [["Foo", "1", %w[develop]]],
          selectors: [sel("feat-x", "main")],
          expected: [] },

        { id: "F4", rule: "R1", title: "one consumer has the branch, another only the fallback",
          pacts: [["Foo", "1", %w[main]], ["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[main]]],
          selectors: [sel("feat-x", "main")],
          expected: [["Foo", "2", %w[branch:feat-x]], ["Foo2", "3", %w[branch:feat-x->main]]] },

        { id: "F5", rule: "R1", title: "every consumer has the branch",
          pacts: [["Foo", "1", %w[main]], ["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[main]], ["Foo2", "4", %w[feat-x]]],
          selectors: [sel("feat-x", "main")],
          expected: [["Foo", "2", %w[branch:feat-x]], ["Foo2", "4", %w[branch:feat-x]]] },

        { id: "F6", rule: "R1", title: "one consumer has the branch, another has neither",
          pacts: [["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[develop]]],
          selectors: [sel("feat-x", "main")],
          expected: [["Foo", "2", %w[branch:feat-x]]] },

        { id: "F7", rule: "R1", title: "the latest branch version wins over an older one",
          pacts: [["Foo", "1", %w[main]], ["Foo", "2", %w[feat-x]], ["Foo", "5", %w[feat-x]]],
          selectors: [sel("feat-x", "main")],
          expected: [["Foo", "5", %w[branch:feat-x]]] },

        { id: "F8", rule: "R1", title: "the latest fallback version wins over an older one",
          pacts: [["Foo", "1", %w[main]], ["Foo", "6", %w[main]]],
          selectors: [sel("feat-x", "main")],
          expected: [["Foo", "6", %w[branch:feat-x->main]]] },

        { id: "F9", rule: "R1", title: "one version is on both the branch and the fallback",
          pacts: [["Foo", "2", %w[feat-x main]]],
          selectors: [sel("feat-x", "main")],
          expected: [["Foo", "2", %w[branch:feat-x]]] },

        { id: "C1", rule: "R1", title: "a scoped selector's consumer has only the fallback while another consumer has the branch",
          pacts: [["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[main]]],
          selectors: [sel("feat-x", "main", consumer: "Foo2")],
          expected: [["Foo2", "3", %w[branch:feat-x->main]]] },

        { id: "C2", rule: "R1", title: "a scoped selector's consumer has the branch while another consumer has only the fallback",
          pacts: [["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[main]]],
          selectors: [sel("feat-x", "main", consumer: "Foo")],
          expected: [["Foo", "2", %w[branch:feat-x]]] },

        { id: "C3", rule: "R1", title: "a scoped selector's consumer has neither branch while another consumer has the fallback",
          pacts: [["Foo", "1", %w[main]], ["Foo2", "3", %w[develop]]],
          selectors: [sel("feat-x", "main", consumer: "Foo2")],
          expected: [] },

        { id: "I1", rule: "R2", title: "a plain branch selector selects another consumer's branch pact beside a fallback selector scoped to Foo2",
          pacts: [["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[main]]],
          selectors: [sel("feat-x"), sel("feat-x", "main", consumer: "Foo2")],
          expected: [["Foo", "2", %w[branch:feat-x]], ["Foo2", "3", %w[branch:feat-x->main]]] },

        { id: "I2", rule: "R2", title: "two fallback selectors with different branches fall back for each other's consumer",
          pacts: [["Foo", "1", %w[main]], ["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[main]], ["Foo2", "4", %w[feat-y]]],
          selectors: [sel("feat-x", "main"), sel("feat-y", "main")],
          expected: [
            ["Foo", "1", %w[branch:feat-y->main]], ["Foo", "2", %w[branch:feat-x]],
            ["Foo2", "3", %w[branch:feat-x->main]], ["Foo2", "4", %w[branch:feat-y]]
          ] },

        { id: "I3", rule: "R2", title: "two fallback selectors share a branch but have different fallbacks",
          pacts: [["Foo2", "3", %w[main]], ["Foo2", "7", %w[develop]]],
          selectors: [sel("feat-x", "main"), sel("feat-x", "develop")],
          expected: [["Foo2", "3", %w[branch:feat-x->main]], ["Foo2", "7", %w[branch:feat-x->develop]]] },

        { id: "M1", rule: "R2", title: "a plain selector for the fallback branch also selects the fallback pact, so the two merge",
          pacts: [["Foo", "1", %w[main]], ["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[main]]],
          selectors: [sel("feat-x", "main"), sel("main")],
          expected: [["Foo", "1", %w[branch:main]], ["Foo", "2", %w[branch:feat-x]], ["Foo2", "3", %w[branch:feat-x->main branch:main]]] },

        { id: "M2", rule: "R2", title: "a tag selector also selects the fallback pact, so the two merge",
          pacts: [["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[main], { tags: %w[prod] }]],
          selectors: [sel("feat-x", "main"), tag_sel("prod")],
          expected: [["Foo", "2", %w[branch:feat-x]], ["Foo2", "3", %w[branch:feat-x->main prod]]] },

        { id: "X1", rule: "R2", title: "a fallbackTag selector and a fallbackBranch selector each fall back on their own terms",
          pacts: [["Foo", "1", %w[main], { tags: %w[master] }], ["Foo", "2", %w[feat-x], { tags: %w[feat-x] }]],
          selectors: [sel("feat-y", "main"), tag_sel("feat-y", "master")],
          expected: [["Foo", "1", %w[branch:feat-y->main feat-y->master]]] },

        { id: "D1", rule: "R2", title: "the fallback pact has the same content as another consumer version's branch pact",
          pacts: [["Foo", "1", %w[main], { content: "a" }], ["Foo", "2", %w[feat-x], { content: "a" }], ["Foo2", "3", %w[main]]],
          selectors: [sel("feat-x", "main")],
          expected: [["Foo", "2", %w[branch:feat-x]], ["Foo2", "3", %w[branch:feat-x->main]]] },

        { id: "P1", rule: "R3", title: "a consumer's branch pact belongs to another provider",
          pacts: [["Foo2", "3", %w[main]], ["Foo2", "4", %w[feat-x], { provider: "Baz" }]],
          selectors: [sel("feat-x", "main")],
          expected: [["Foo2", "3", %w[branch:feat-x->main]]] },

        { id: "P2", rule: "R3", title: "the branch head has no pact with this provider, though an older branch version does",
          pacts: [["Foo2", "3", %w[main]], ["Foo2", "4", %w[feat-x]], ["Foo2", "5", %w[feat-x], { provider: "Baz" }]],
          selectors: [sel("feat-x", "main")],
          expected: [["Foo2", "3", %w[branch:feat-x->main]]] },
      ]

      # MARK: Runner

      def create_pacts(pacts)
        pacts.each do | consumer, version, branches, options = {} |
          provider = options.fetch(:provider, "Bar")
          td.create_pact_with_hierarchy(consumer, version, provider, pact_content(consumer, provider, options[:content]))
          branches.each { | branch | PactBroker::Versions::BranchVersionRepository.new.add_branch(td.consumer_version, branch) }
          options.fetch(:tags, []).each { | tag | td.create_consumer_version_tag(tag) }
        end
      end

      def pact_content(consumer, provider, content_key)
        return nil unless content_key
        { consumer: { name: consumer }, provider: { name: provider }, interactions: [], content: content_key }.to_json
      end

      def label(selector)
        if selector.branch
          selector.fallback_branch ? "branch:#{selector.branch}->#{selector.fallback_branch}" : "branch:#{selector.branch}"
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
        Service.find_for_verification("Bar", provider_branch, provider_tags, Selectors.new(sel("feat-x", "main")), options)
          .collect { | p | [p.consumer_name, p.consumer_version_number, p.wip, p.pending] }
          .sort
      end

      describe "W1 (R4) with a provider tag, the fallback pact is explicitly selected, so it is not WIP" do
        before do
          create_pacts([["Foo", "1", %w[main]], ["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[main]]])
        end

        it "returns Foo2's fallback pact as pending, and only Foo's unselected main pact as WIP" do
          expect(find_for_verification(provider_tags: ["feat-x"], include_wip: true)).to eq [
            ["Foo", "1", true, true], ["Foo", "2", false, true], ["Foo2", "3", false, true]
          ]
        end
      end

      describe "W2 (R5) with a provider tag, the fallback pact is not pending once that tag has verified it" do
        before do
          create_pacts([["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[main]]])
          td.create_verification(provider_version: "1", tag_names: ["feat-x"])
        end

        it "returns Foo2's fallback pact as not pending" do
          expect(find_for_verification(provider_tags: ["feat-x"])).to eq [["Foo", "2", false, true], ["Foo2", "3", false, false]]
        end
      end

      describe "W3 (R4) with a provider branch, the fallback pact is explicitly selected, so it is not WIP" do
        before do
          create_pacts([["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[main]]])
        end

        it "returns Foo2's fallback pact as pending and not WIP" do
          expect(find_for_verification(provider_branch: "feat-x", include_wip: true)).to eq [
            ["Foo", "2", false, true], ["Foo2", "3", false, true]
          ]
        end
      end

      describe "W4 (R5) with a provider branch, the fallback pact is not pending once that branch has verified it" do
        before do
          create_pacts([["Foo", "2", %w[feat-x]], ["Foo2", "3", %w[main]]])
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
