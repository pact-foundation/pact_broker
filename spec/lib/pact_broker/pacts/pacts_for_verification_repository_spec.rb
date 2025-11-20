require "pact_broker/pacts/pacts_for_verification_repository"

# ============================================================================
# WHAT THIS TEST FILE TESTS
# ============================================================================
# This file tests the PactsForVerificationRepository, which finds pacts that
# a provider should verify. There are two main types of pacts:
#
# 1. REGULAR PACTS: Explicitly requested pacts (e.g., "latest on main branch")
# 2. WIP PACTS: "Work In Progress" pacts that are new and haven't been 
#    successfully verified yet
#
# WIP PACT RULES:
# - Only HEAD versions count (latest version for each branch/tag)
# - A pact is WIP if it hasn't been successfully verified on the provider branch
# - Once verified with wip:false, it's no longer WIP
# - Verifications with wip:true don't count (they're still WIP)
# - Only considers pacts published after a certain date (include_wip_pacts_since)
# ============================================================================

module PactBroker
  module Pacts
    describe PactsForVerificationRepository do
      let(:repository) { PactsForVerificationRepository.new }
      let(:provider_name) { "TestProvider" }
      let(:consumer_name) { "TestConsumer" }

      # ========================================================================
      # HELPER: Basic test data setup
      # Creates a simple consumer-provider relationship with 2 consumer versions
      # ========================================================================
      shared_context "basic test data" do
        before do
          td.create_consumer(consumer_name)
            .create_provider(provider_name)
            .create_consumer_version("1.0.0", tag_names: ["main", "prod"])
            .create_pact
            .create_verification(provider_version: "2.0.0")
            .create_consumer_version("1.1.0", tag_names: ["main"])
            .create_pact
        end
      end

      # ========================================================================
      # HELPER: Validates pact results
      # ========================================================================
      shared_examples "returns valid pact results" do
        it "returns an array of pacts with correct consumer and provider" do
          expect(result).to be_a(Array).and be_present
          expect(result.first.consumer_name).to eq(consumer_name)
          expect(result.first.provider_name).to eq(provider_name) if result.first.respond_to?(:provider_name)
        end
      end

      # ========================================================================
      # TESTS: #find - Finding explicitly requested pacts
      # This method finds pacts based on selectors (e.g., "latest for tag main")
      # ========================================================================
      describe "#find" do
        include_context "basic test data"

        let(:result) { repository.find(provider_name, consumer_version_selectors) }

        context "with empty consumer version selectors" do
          let(:consumer_version_selectors) { Selectors.new }

          it_behaves_like "returns valid pact results"
          
          it "returns SelectedPact instances" do
            expect(result.first).to be_a(SelectedPact)
          end
        end

        context "with specific tag selector" do
          let(:consumer_version_selectors) do
            Selectors.new([Selector.latest_for_tag("main").for_consumer(consumer_name)])
          end

          it_behaves_like "returns valid pact results"
        end

        context "with branch selector" do
          let(:consumer_version_selectors) do
            Selectors.new([Selector.for_main_branch.for_consumer(consumer_name)])
          end

          before do
            td.create_consumer_version("1.2.0", branch: "main").create_pact
          end

          it_behaves_like "returns valid pact results"
        end
      end

      # ========================================================================
      # TESTS: #find_wip - Finding "Work In Progress" pacts
      # WIP pacts are new pacts that haven't been successfully verified yet
      # ========================================================================
      describe "#find_wip" do
        include_context "basic test data"
        
        let(:explicitly_specified_verifiable_pacts) { [] }
        let(:options) { { include_wip_pacts_since: Date.today - 1 } }

        shared_examples "returns WIP verifiable pacts" do
          it "returns array of VerifiablePact with wip=true" do
            expect(result).to be_a(Array)
            result.each do |pact|
              expect(pact).to be_a(VerifiablePact)
              expect(pact.wip).to be(true)
            end
          end
        end

        context "with provider tags" do
          let(:result) do
            repository.find_wip(provider_name, nil, ["main"], explicitly_specified_verifiable_pacts, options)
          end

          it_behaves_like "returns WIP verifiable pacts"
        end

        context "with provider branch" do
          let(:result) do
            repository.find_wip(provider_name, "main", [], explicitly_specified_verifiable_pacts, options)
          end

          it_behaves_like "returns WIP verifiable pacts"
        end

        context "without provider tags or branch" do
          it "returns empty array" do
            result = repository.find_wip(provider_name, nil, [], explicitly_specified_verifiable_pacts, options)
            expect(result).to eq([])
          end
        end
      end
      # ========================================================================
      # TESTS: Integration with database scopes
      # Tests that verify the repository works correctly with complex queries
      # ========================================================================
      describe "integration with database scopes" do
        context "when a pact has multiple verification results" do
          let(:consumer_name) { "MultiVerConsumer" }
          let(:provider_name) { "MultiVerProvider" }
          let(:branch) { "main" }
          let(:options) { { include_wip_pacts_since: Date.today - 10 } }

          before do
            td.create_consumer(consumer_name)
              .create_provider(provider_name)
              .create_consumer_version("1.0.0", branch: branch)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.0.0", branch: branch)
              .create_verification(provider_version: "1.0.0", branch: branch, success: true, number: 1)
              .create_verification(provider_version: "2.0.0", branch: branch, success: true, number: 2)
          end

          it "returns empty when pact is verified by latest provider version" do
            expect(repository.find_wip(provider_name, branch, [], [], options)).to be_empty
          end

          it "returns pact as WIP when new unverified version is published" do
            td.create_consumer_version("2.0.0", branch: branch)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "2.0.0", branch: branch)
            
            result = repository.find_wip(provider_name, branch, [], [], options)
            expect(result.size).to eq(1)
            expect(result.first.consumer_version.number).to eq("2.0.0")
            expect(result.first.wip?).to be true
          end
        end

        context "when pact publications exist with various filters" do
          before do
            td.create_consumer("OldConsumer")
              .create_consumer_version("1.0.0", tag_names: ["main"])
              .create_pact_with_hierarchy("OldConsumer", "1.0.0", provider_name)
            
            td.create_consumer("NewConsumer")
              .create_consumer_version("2.0.0", tag_names: ["main"])
              .create_pact_with_hierarchy("NewConsumer", "2.0.0", provider_name)
              .create_verification(provider_version: "1.0.0", success: true)
          end

          it "correctly applies date filters and joins" do
            selectors = Selectors.new([Selector.latest_for_tag("main").for_consumer("NewConsumer")])
            result = repository.find(provider_name, selectors)
            
            expect(result).not_to be_empty
            expect(result.map(&:consumer_name)).to include("NewConsumer")
          end
        end
      end

      # ========================================================================
      # TESTS: #find_wip_pact_versions_for_provider_by_provider_branch
      # 
      # This is the core WIP detection logic for provider branches.
      # Key concepts:
      # - HEAD: The latest version for a branch or tag
      # - WIP: A pact that hasn't been successfully verified (wip:false) yet
      # - Only HEAD versions are considered for WIP
      # - Pacts verified on OTHER branches before THIS branch was created
      #   are not considered WIP for this branch
      # ========================================================================
      describe "#find_wip_pact_versions_for_provider_by_provider_branch" do
        let(:provider_version_branch) { "new-branch" }
        let(:wip_start_date) { Date.today - 30 }
        let(:options) { { include_wip_pacts_since: wip_start_date } }
        let(:explicitly_specified_verifiable_pacts) { [] }

        # Simple helper to set up consumer/provider names for each test
        shared_context "branch-based WIP test setup" do |consumer:, provider:, branch:|
          let(:consumer_name) { consumer }
          let(:provider_name) { provider }
          let(:consumer_branch) { branch }
        end

        # ====================================================================
        # SCENARIO: Pacts verified on another branch before this branch existed
        # 
        # Timeline:
        # 1. Consumer v1.0.0 verified by provider on "old-branch"
        # 2. Consumer v1.1.0 verified by provider on "new-branch" (our test branch)
        # 3. Consumer v1.2.0 published but not verified yet
        #
        # Expected: Only v1.2.0 should be WIP (v1.0.0 was verified before 
        # "new-branch" existed, so it's not WIP for this branch)
        # ====================================================================
        context "pacts verified by another branch before this branch was created" do
          include_context "branch-based WIP test setup", consumer: "BranchConsumer", provider: "BranchProvider", branch: "consumer-main"

          before do
            td.set_now(Date.today - 10)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.0.0", branch: consumer_branch, tags: ["main"])
              .create_verification(provider_version: "10.0.0", branch: "old-branch", success: true)
              .add_days(1)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.1.0", branch: consumer_branch, tags: ["main"])
              .create_verification(provider_version: "10.1.0", branch: provider_version_branch, success: true)
              .add_days(1)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.2.0", branch: consumer_branch, tags: ["main"])
          end

          it "returns only unverified head pact as WIP with deduplication" do
            result = repository.find_wip(provider_name, provider_version_branch, [], explicitly_specified_verifiable_pacts, options)
            
            expect(result.size).to eq(1)
            expect(result.first).to be_a(VerifiablePact).and be_wip
            expect(result.first.consumer_version.number).to eq("1.2.0")
            expect(result.first.provider_branch).to eq(provider_version_branch)
            expect(result.map { |vp| vp.consumer_version.number }).to eq(["1.2.0"])
          end
        end

        # ====================================================================
        # SCENARIO: Explicitly specified pacts should be excluded from WIP
        #
        # When a pact is explicitly requested (e.g., via selector), it shouldn't
        # also appear in the WIP list to avoid duplication
        # ====================================================================
        context "explicitly specified verifiable pacts excluded" do
          include_context "branch-based WIP test setup", consumer: "ExplicitConsumer", provider: "ExplicitProvider", branch: "consumer-main"
          
          let(:selectors_for_explicit) { Selectors.new([Selector.overall_latest.for_consumer(consumer_name)]) }
          let(:explicitly_specified_verifiable_pacts) do
            VerifiablePact.create_for_wip_for_provider_branch(explicit_pact, selectors_for_explicit, provider_version_branch).yield_self { |vp| [vp] }
          end
          let(:explicit_pact) { td.and_return(:pact) }

          before do
            td.set_now(Date.today - 5)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.0.0", branch: consumer_branch, tags: ["main"])
              .create_verification(provider_version: "9.9.9", branch: provider_version_branch, success: true)
              .add_days(1)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.1.0", branch: consumer_branch, tags: ["main"])
          end

          it "excludes explicitly specified pacts from WIP results" do
            wip_without_exclusion = repository.find_wip(provider_name, provider_version_branch, [], [], options)
            expect(wip_without_exclusion.map { |vp| vp.consumer_version.number }).to eq(["1.1.0"])

            wip_with_exclusion = repository.find_wip(provider_name, provider_version_branch, [], explicitly_specified_verifiable_pacts, options)
            expect(wip_with_exclusion).to be_empty
          end
        end

        # ====================================================================
        # SCENARIO: No pacts after wip_start_date
        # 
        # If all pacts were published before the wip_start_date, none should
        # be considered WIP (the date filter excludes them)
        # ====================================================================
        context "no candidate pacts after wip_start_date" do
          include_context "branch-based WIP test setup", consumer: "NoCandidatesConsumer", provider: "NoCandidatesProvider", branch: "legacy-branch"
          
          let(:options) { { include_wip_pacts_since: Date.today + 1 } }

          before do
            td.set_now(Date.today - 100)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "0.1.0", branch: consumer_branch, tags: ["main"])
              .create_verification(provider_version: "0.0.1", branch: "legacy-provider-branch", success: true)
          end

          it "returns empty list" do
            expect(repository.find_wip(provider_name, provider_version_branch, [], explicitly_specified_verifiable_pacts, options)).to be_empty
          end
        end

        # ====================================================================
        # SCENARIO: Branch-only consumer (no tags)
        #
        # Consumer versions can have branches without tags. WIP detection
        # should work for branch heads even without tags.
        # ====================================================================
        context "branch-only consumer head (no tags)" do
          include_context "branch-based WIP test setup", consumer: "BranchOnlyConsumer", provider: "BranchOnlyProvider", branch: "branch-only"
          
          let(:provider_version_branch) { "provider-branch-only" }
          let(:options) { { include_wip_pacts_since: Date.today - 10 } }

          before do
            td.set_now(Date.today - 5)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.0.0", branch: consumer_branch)
              .create_verification(provider_version: "1.0.0", branch: provider_version_branch, success: true)
              .add_days(1)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.1.0", branch: consumer_branch)
          end

          it "treats head pact without tags as WIP using branch selector logic" do
            result = repository.find_wip(provider_name, provider_version_branch, [], [], options)
            
            expect(result.size).to eq(1)
            expect(result.first).to be_wip
            expect(result.first.consumer_version.number).to eq("1.1.0")
            expect(result.first.selectors.any? { |s| s.branch == consumer_branch }).to be true
          end
        end

        # ====================================================================
        # SCENARIO: Already verified pacts should not be WIP
        #
        # When a pact has been successfully verified with wip:false on the
        # same provider branch, it's no longer WIP. Only unverified pacts
        # should be returned.
        # ====================================================================
        context "pacts already successfully verified by the same provider branch" do
          include_context "branch-based WIP test setup", consumer: "VerifiedConsumer", provider: "VerifiedProvider", branch: "consumer-main"
          
          let(:provider_version_branch) { "main" }
          let(:options) { { include_wip_pacts_since: Date.today - 10 } }

          before do
            td.set_now(Date.today - 8)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.0.0", branch: consumer_branch, tags: ["dev"])
              .create_verification(provider_version: "1.0.0", branch: provider_version_branch, success: true, wip: false)
              .add_days(1)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.1.0", branch: consumer_branch, tags: ["dev"])
              .create_verification(provider_version: "1.1.0", branch: provider_version_branch, success: true, wip: false)
              .add_days(1)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.2.0", branch: consumer_branch, tags: ["dev"])
          end

          it "excludes already verified pacts and returns only unverified as WIP" do
            result = repository.find_wip(provider_name, provider_version_branch, [], [], options)
            
            expect(result.size).to eq(1)
            expect(result.first).to be_wip
            expect(result.first.consumer_version.number).to eq("1.2.0")
            expect(result.first.provider_branch).to eq(provider_version_branch)
          end

          it "generates query with branch inclusion filter for same branch verifications" do
            result = repository.find_wip(provider_name, provider_version_branch, [], [], options)
            expect(result).to be_present
          end
        end

        # ====================================================================
        # SCENARIO: WIP verifications (wip:true) don't count as "verified"
        #
        # A verification with wip:true means "this was a WIP verification".
        # The pact remains WIP until it gets a successful verification with
        # wip:false.
        #
        # Setup:
        # - v1.0.0: Failed verification with wip:true (still WIP)
        # - v1.1.0: Successful verification with wip:true (still WIP)
        #
        # Both should be returned as WIP because they need wip:false verification
        # ====================================================================
        context "WIP verification with failed attempts (wip: true)" do
          include_context "branch-based WIP test setup", consumer: "WipFailConsumer", provider: "WipFailProvider", branch: "consumer-branch"
          
          let(:provider_version_branch) { "provider-main" }
          let(:options) { { include_wip_pacts_since: Date.today - 10 } }

          before do
            td.set_now(Date.today - 7)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.0.0", branch: consumer_branch, tags: ["test1"])
              .create_verification(provider_version: "1.0.0", branch: provider_version_branch, success: false, wip: true)
              .add_days(1)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.1.0", branch: consumer_branch, tags: ["test2"])
              .create_verification(provider_version: "1.1.0", branch: provider_version_branch, success: true, wip: true)
          end

          it "returns pacts with wip verifications as still WIP" do
            result = repository.find_wip(provider_name, provider_version_branch, [], [], options)
            
            expect(result.size).to eq(2)
            expect(result.map { |vp| vp.consumer_version.number }).to match_array(["1.0.0", "1.1.0"])
            expect(result.all?(&:wip?)).to be true
          end
        end

        # ====================================================================
        # SCENARIO: Mixed tag and branch consumer versions
        #
        # Consumers can publish pacts with:
        # - Both branch and tag (v1.0.0)
        # - Only branch, no tag (v1.1.0)  
        # - Only tag, no branch (v1.2.0)
        # - Different branch and tag (v1.3.0)
        #
        # WIP detection should find all HEAD versions from both branches
        # and tags, then deduplicate.
        # ====================================================================
        context "mixed tag and branch consumer versions" do
          include_context "branch-based WIP test setup", consumer: "MixedConsumer", provider: "MixedProvider", branch: "feature-branch"
          
          let(:provider_version_branch) { "main" }
          let(:options) { { include_wip_pacts_since: Date.today - 15 } }

          before do
            td.set_now(Date.today - 12)
              # Consumer version with both branch and tag
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.0.0", branch: consumer_branch, tags: ["dev"])
              .create_verification(provider_version: "1.0.0", branch: provider_version_branch, success: true, wip: false)
              .add_days(1)
              # Consumer version with only branch (no tag)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.1.0", branch: consumer_branch)
              .add_days(1)
              # Consumer version with only tag (no branch)
              .create_consumer_version("1.2.0", tag_names: ["feature"])
              .create_pact
              .add_days(1)
              # Consumer version with different branch and tag
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.3.0", branch: "other-branch", tags: ["staging"])
          end

          it "returns WIP pacts from both tag and branch heads, properly deduplicated" do
            result = repository.find_wip(provider_name, provider_version_branch, [], [], options)
            
            # Should include:
            # - 1.1.0 (branch head for "feature-branch", not verified)
            # - 1.2.0 (tag head for "feature", not verified, no branch)
            # - 1.3.0 (branch head for "other-branch" AND tag head for "staging", not verified)
            expect(result.size).to eq(3)
            version_numbers = result.map { |vp| vp.consumer_version.number }.sort
            expect(version_numbers).to eq(["1.1.0", "1.2.0", "1.3.0"])
            expect(result.all?(&:wip?)).to be true
          end
        end

        # ====================================================================
        # SCENARIO: Multiple consumers with different verification states
        #
        # A provider can have pacts from multiple consumers. Each consumer's
        # pacts are evaluated independently for WIP status.
        #
        # Setup:
        # - Consumer1: v1.0.0 verified, v1.1.0 unverified (WIP)
        # - Consumer2: v2.0.0 never verified (WIP)
        # - Consumer3: v3.0.0 and v3.1.0 verified on different branch (both WIP for this branch)
        # ====================================================================
        context "multiple consumers with different verification states" do
          let(:consumer1) { "Consumer1" }
          let(:consumer2) { "Consumer2" }
          let(:consumer3) { "Consumer3" }
          let(:provider_name) { "MultiConsumerProvider" }
          let(:provider_version_branch) { "main" }
          let(:options) { { include_wip_pacts_since: Date.today - 20 } }

          before do
            td.set_now(Date.today - 15)
              # Consumer 1: First version verified on this branch, second version is WIP
              .create_consumer(consumer1)
              .create_provider(provider_name)
              .publish_pact(consumer_name: consumer1, provider_name: provider_name, consumer_version_number: "1.0.0", branch: "main", tags: ["prod"])
              .create_verification(provider_version: "1.0.0", branch: provider_version_branch, success: true, wip: false)
              .add_days(1)
              .publish_pact(consumer_name: consumer1, provider_name: provider_name, consumer_version_number: "1.1.0", branch: "main", tags: ["prod"])
              .add_days(1)
              # Consumer 2: Never verified, so it's WIP
              .create_consumer(consumer2)
              .publish_pact(consumer_name: consumer2, provider_name: provider_name, consumer_version_number: "2.0.0", branch: "develop", tags: ["dev"])
              .add_days(1)
              # Consumer 3: Two versions, both verified on a DIFFERENT branch, so both are WIP for THIS branch
              .create_consumer(consumer3)
              .publish_pact(consumer_name: consumer3, provider_name: provider_name, consumer_version_number: "3.0.0", branch: "release", tags: ["staging"])
              .create_verification(provider_version: "3.0.0", branch: "other-branch", success: true, wip: false)
              .add_days(1)
              .publish_pact(consumer_name: consumer3, provider_name: provider_name, consumer_version_number: "3.1.0", branch: "release", tags: ["rc"])
          end

          it "correctly identifies WIP pacts across multiple consumers" do
            result = repository.find_wip(provider_name, provider_version_branch, [], [], options)
            
            # Should include:
            # - Consumer1: 1.1.0 (branch head, not verified on this branch)
            # - Consumer2: 2.0.0 (branch head, never verified)
            # - Consumer3: 3.0.0 (tag head for "staging") and 3.1.0 (tag head for "rc", branch head for "release")
            #              Both verified on different branch, so both are WIP for this branch
            expect(result.size).to eq(4)
            
            consumer_versions = result.group_by { |vp| vp.consumer.name }
            expect(consumer_versions[consumer1].map { |vp| vp.consumer_version.number }).to eq(["1.1.0"])
            expect(consumer_versions[consumer2].map { |vp| vp.consumer_version.number }).to eq(["2.0.0"])
            expect(consumer_versions[consumer3].map { |vp| vp.consumer_version.number }.sort).to eq(["3.0.0", "3.1.0"])
            expect(result.all?(&:wip?)).to be true
          end
        end

        # ====================================================================
        # SCENARIO: Date filtering - pacts before wip_start_date are excluded
        #
        # The wip_start_date option filters out old pacts. Only pacts published
        # AFTER this date are considered for WIP.
        #
        # Note: This test manually sets created_at timestamps because the
        # test data builder doesn't automatically use the set_now() time for
        # pact publications.
        # ====================================================================
        context "pact published before wip_start_date" do
          include_context "branch-based WIP test setup", consumer: "OldPactConsumer", provider: "OldPactProvider", branch: "main"
          
          let(:provider_version_branch) { "main" }
          let(:wip_start_date) { Date.today - 5 }
          let(:options) { { include_wip_pacts_since: wip_start_date } }

          before do
            td.set_now(Date.today - 10)
              # Old pact published before wip_start_date
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.0.0", branch: consumer_branch, tags: ["old"])
            
            # Manually set the created_at for the old pact to before wip_start_date
            PactBroker::Pacts::PactPublication.where(consumer_version: PactBroker::Domain::Version.where(number: "1.0.0").all)
              .update(created_at: Date.today - 10)
            
            td.add_days(6) # Now after wip_start_date
              # New pact published after wip_start_date
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.1.0", branch: consumer_branch, tags: ["new"])
            
            # Manually set the created_at for the new pact to after wip_start_date
            PactBroker::Pacts::PactPublication.where(consumer_version: PactBroker::Domain::Version.where(number: "1.1.0").all)
              .update(created_at: Date.today - 4)
          end

          it "excludes pacts published before wip_start_date" do
            result = repository.find_wip(provider_name, provider_version_branch, [], [], options)
            
            # Only v1.1.0 should be returned (v1.0.0 is too old)
            expect(result.size).to eq(1)
            expect(result.first.consumer_version.number).to eq("1.1.0")
            expect(result.first.wip?).to be true
          end
        end

        # ====================================================================
        # SCENARIO: Verification on same branch but marked wip:true
        #
        # Even if a pact was successfully verified (success:true), if that
        # verification was marked as wip:true, the pact is still considered WIP.
        # It needs a verification with wip:false to no longer be WIP.
        # ====================================================================
        context "verification on same branch but marked as wip: true" do
          include_context "branch-based WIP test setup", consumer: "WipMarkedConsumer", provider: "WipMarkedProvider", branch: "develop"
          
          let(:provider_version_branch) { "develop" }
          let(:options) { { include_wip_pacts_since: Date.today - 10 } }

          before do
            td.set_now(Date.today - 8)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.0.0", branch: consumer_branch, tags: ["test"])
              # Verification exists but was WIP at the time (wip:true doesn't count as "verified")
              .create_verification(provider_version: "1.0.0", branch: provider_version_branch, success: true, wip: true)
          end

          it "still returns pact as WIP because previous verification was marked wip: true" do
            result = repository.find_wip(provider_name, provider_version_branch, [], [], options)
            
            expect(result.size).to eq(1)
            expect(result.first.consumer_version.number).to eq("1.0.0")
            expect(result.first.wip?).to be true
          end
        end

        # ====================================================================
        # SCENARIO: Deduplication - same pact as both branch and tag head
        #
        # A consumer version can be both a branch head AND a tag head.
        # The WIP detection finds it from both paths but should return it
        # only once (deduplicated).
        # ====================================================================
        context "same pact appears in both branch and tag heads" do
          include_context "branch-based WIP test setup", consumer: "DuplicateConsumer", provider: "DuplicateProvider", branch: "feature"
          
          let(:provider_version_branch) { "main" }
          let(:options) { { include_wip_pacts_since: Date.today - 10 } }

          before do
            td.set_now(Date.today - 8)
              # Same consumer version is both branch head AND tag head
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.0.0", branch: consumer_branch, tags: ["v1.0"])
          end

          it "deduplicates and returns only one WIP entry" do
            result = repository.find_wip(provider_name, provider_version_branch, [], [], options)
            
            # Should appear only once, even though it's found via both branch and tag
            expect(result.size).to eq(1)
            expect(result.first.consumer_version.number).to eq("1.0.0")
            expect(result.first.wip?).to be true
          end
        end

        # ====================================================================
        # SCENARIO: Only HEAD versions are WIP candidates
        #
        # Multiple versions exist on the same branch/tag, but only the LATEST
        # (head) version is considered for WIP. Older versions are ignored.
        #
        # Setup:
        # - v1.0.0, v1.1.0, v1.2.0 all on same branch and tag
        # - Only v1.2.0 (the head) should be returned
        # ====================================================================
        context "non-head consumer versions" do
          include_context "branch-based WIP test setup", consumer: "NonHeadConsumer", provider: "NonHeadProvider", branch: "main"
          
          let(:provider_version_branch) { "main" }
          let(:options) { { include_wip_pacts_since: Date.today - 10 } }

          before do
            td.set_now(Date.today - 8)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.0.0", branch: consumer_branch, tags: ["v1"])
              .add_days(1)
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.1.0", branch: consumer_branch, tags: ["v1"])
              .add_days(1)
              # Latest version on both branch and tag
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.2.0", branch: consumer_branch, tags: ["v1"])
          end

          it "returns only head pact versions as WIP" do
            result = repository.find_wip(provider_name, provider_version_branch, [], [], options)
            
            # Only the latest version (head) is WIP, not the older ones
            expect(result.size).to eq(1)
            expect(result.first.consumer_version.number).to eq("1.2.0")
            expect(result.first.wip?).to be true
          end
        end

        # ====================================================================
        # SCENARIO: Edge case - verification timing vs branch creation
        #
        # Complex timing scenario:
        # 1. Pact v1.0.0 published
        # 2. Pact verified on "old-provider-branch"
        # 3. Provider creates "provider-new-branch" (our test branch)
        # 4. Pact v1.1.0 published
        #
        # Result: v1.0.0 was verified before this branch existed, so it's not
        # WIP for this branch. Only v1.1.0 is WIP.
        # ====================================================================
        context "edge case: verification on branch after pact was created but before branch was created" do
          include_context "branch-based WIP test setup", consumer: "TimingConsumer", provider: "TimingProvider", branch: "consumer-main"
          
          let(:provider_version_branch) { "provider-new-branch" }
          let(:options) { { include_wip_pacts_since: Date.today - 30 } }

          before do
            td.set_now(Date.today - 20)
              # Pact published
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.0.0", branch: consumer_branch, tags: ["release"])
              .add_days(5)
              # Verification on different branch BEFORE provider_new_branch exists
              .create_verification(provider_version: "1.0.0", branch: "old-provider-branch", success: true, wip: false)
              .add_days(5)
              # First commit on provider_new_branch (branch is created NOW)
              .create_provider_version("2.0.0", branch: provider_version_branch)
              .add_days(1)
              # New pact AFTER provider_new_branch was created
              .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.1.0", branch: consumer_branch, tags: ["release"])
          end

          it "excludes pacts verified by other branches before this branch existed" do
            result = repository.find_wip(provider_name, provider_version_branch, [], [], options)
            
            # Should only include 1.1.0 (published after the provider branch was created)
            # 1.0.0 was verified before provider_new_branch existed, so it's not WIP
            expect(result.map { |vp| vp.consumer_version.number }).to include("1.1.0")
          end
        end

        # ====================================================================
        # SCENARIOS: Empty result cases
        #
        # These tests verify that empty arrays are returned when appropriate
        # ====================================================================
        context "empty result scenarios" do
          include_context "branch-based WIP test setup", consumer: "EmptyConsumer", provider: "EmptyProvider", branch: "main"
          
          let(:provider_version_branch) { "main" }
          let(:options) { { include_wip_pacts_since: Date.today - 10 } }

          context "when all pacts are verified" do
            before do
              td.set_now(Date.today - 8)
                .publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.0.0", branch: consumer_branch, tags: ["prod"])
                .create_verification(provider_version: "1.0.0", branch: provider_version_branch, success: true, wip: false)
            end

            it "returns empty array" do
              result = repository.find_wip(provider_name, provider_version_branch, [], [], options)
              expect(result).to be_empty
            end
          end

          context "when no pacts exist for provider" do
            before do
              # Create provider but no pacts
              td.create_provider(provider_name)
            end

            it "returns empty array" do
              result = repository.find_wip(provider_name, provider_version_branch, [], [], options)
              expect(result).to be_empty
            end
          end
        end

        # ====================================================================
        # SCENARIO: Performance test with many tags
        #
        # A consumer version can have many tags. Even if it's the head for
        # 20 different tags, it should only be returned once (deduplicated).
        # ====================================================================
        context "performance: large number of consumer tags" do
          include_context "branch-based WIP test setup", consumer: "ManyTagsConsumer", provider: "ManyTagsProvider", branch: "main"
          
          let(:provider_version_branch) { "main" }
          let(:options) { { include_wip_pacts_since: Date.today - 10 } }

          before do
            td.set_now(Date.today - 8)
            
            # Create a consumer version with 20 tags (head for all of them)
            tags = (1..20).map { |i| "tag-#{i}" }
            td.publish_pact(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: "1.0.0", branch: consumer_branch, tags: tags)
          end

          it "handles consumer with many tags efficiently and returns single deduplicated result" do
            result = repository.find_wip(provider_name, provider_version_branch, [], [], options)
            
            # Should return the same pact only once despite being head for 20 tags
            expect(result.size).to eq(1)
            expect(result.first.consumer_version.number).to eq("1.0.0")
            expect(result.first.wip?).to be true
          end
        end
      end
    end
  end
end