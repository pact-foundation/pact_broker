require "pact_broker/matrix/service"

module PactBroker
  module Matrix
    describe Service do
      describe "find" do
        subject { Service.can_i_deploy(selectors, options) }

        # Useful for eyeballing the messages to make sure they read nicely
        # after do
        #   require 'pact_broker/api/decorators/reason_decorator'
        #   subject.deployment_status_summary.reasons.each do | reason |
        #     puts reason
        #     puts PactBroker::Api::Decorators::ReasonDecorator.new(reason).to_s
        #   end
        # end

        let(:options) { {} }

        describe "find" do
          let(:selectors) do
            [ UnresolvedSelector.new(pacticipant_name: "foo") ]
          end

          let(:options) do
            { latest: true, tag: "prod", latestby: "cvp" }
          end

          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_verification(provider_version: "2", tag_names: ["prod"])
          end

          it "returns a QueryResultsWithDeploymentStatusSummary" do
            expect(subject.rows).to be_a(Array)
            expect(subject.selectors).to be selectors
            expect(subject.options).to be options
            expect(subject.resolved_selectors).to be_a(Array)
            expect(subject.resolved_selectors.count).to eq 2
            expect(subject.integrations.count).to eq 1
            expect(subject.deployment_status_summary).to be_a(DeploymentStatusSummary)
          end
        end

        describe "when deploying a version of a provider with multiple versions of a consumer in production that is missing a verification for the latest prod version" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_consumer_version_tag("prod")
              .create_verification(provider_version: "10", tag_names: ["test"])
              .create_consumer_version("2", tag_names: ["prod"])
              .create_pact
          end

          let(:selectors) { [ UnresolvedSelector.new(pacticipant_name: "Bar", latest: true, tag: "test") ]}
          let(:options) { { tag: "prod", latestby: "cvp" } }

          it "does not allow the provider to be deployed" do
            expect(subject.deployment_status_summary).to_not be_deployable
          end
        end

        describe "when deploying a consumer that has not been verified by any providers" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_provider("Baz")
              .create_pact
          end
          let(:selectors) do
            [ UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1") ]
          end

          it "returns 2 integrations" do
            expect(subject.integrations.size).to eq 2
          end

          it "but cannot resolve selectors for the providers" do
            expect(subject.resolved_selectors.size).to eq 1
          end

          it "does not allow the consumer to be deployed" do
            expect(subject.deployment_status_summary).to_not be_deployable
          end
        end

        describe "when deploying a consumer that has two providers in prod, but it is not verified by one of the prod provider versions, pact_broker-client issue #33" do
          before do
            td.create_pact_with_hierarchy("Foo", "3.0.0", "Bar")
              .create_verification(provider_version: "10.0.0", tag_names: ["prod"])
              .create_provider("Baz")
              .create_pact
              .create_verification(provider_version: "20", tag_names:["prod"])
              .create_consumer_version("2.0.0")
              .use_provider("Bar")
              .create_pact
              .create_verification(provider_version: "11.0.0", tag_names: ["prod"])
          end

          let(:selectors) do
            [ UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "3.0.0") ]
          end

          let(:options) { {latest: true, tag: "prod", latestby: "cvp"} }

          it "returns 2 integrations" do
            expect(subject.integrations.size).to eq 2
          end

          it "returns 1 row with a verification" do
            expect(subject.rows.count(&:has_verification?)).to eq 1
          end

          it "returns 1 row without a verification" do
            expect(subject.rows.count{ |row| !row.has_verification? }).to eq 1
          end

          it "does not allow the consumer to be deployed" do
            expect(subject.deployment_status_summary).to_not be_deployable
          end
        end

        describe "when deploying an old version of a consumer that has added a new provider since that version" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_verification(provider_version: "2")
              .create_consumer_version("2")
              .create_pact
              .create_verification(provider_version: "3")
              .create_provider("Wiffle")
              .create_pact
              .create_verification(provider_version: "10")
          end

          let(:selectors) do
            [ UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1") ]
          end

          it "allows the old version of the consumer to be deployed" do
            expect(subject.deployment_status_summary).to be_deployable
          end
        end

        describe "when the specified version does not exist" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
          end

          let(:selectors) do
            [ UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "5") ]
          end

          it "does not allow the app to be deployed" do
            expect(subject.deployment_status_summary).to_not be_deployable
          end
        end

        describe "when deploying a provider to prod for the first time and the consumer is not yet deployed" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_verification(provider_version: "2")
          end

          let(:selectors) do
            [ UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "2") ]
          end

          let(:options) do
            { latest: true, tag: "prod", latestby: "cvp" }
          end

          subject { Service.can_i_deploy(selectors, options) }

          it "allows the app to be deployed" do
            expect(subject.deployment_status_summary).to be_deployable
          end
        end

        describe "when deploying a consumer to prod for the first time and the provider is not yet deployed" do
          before do
            td.create_pact_with_verification("Foo", "1", "Bar", "2")
          end

          let(:selectors) do
            [ UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1") ]
          end

          let(:options) do
            { latest: true, tag: "prod", latestby: "cvp" }
          end

          it "does not allow the app to be deployed" do
            expect(subject.deployment_status_summary).to_not be_deployable
          end
        end

        describe "when deploying an app that is both a consumer and a provider to prod for the first time and the downstream provider is not yet deployed" do
          before do
            td.create_pact_with_verification("Foo", "1", "Bar", "2")
            .use_consumer("Bar")
            .use_consumer_version("2")
            .create_provider("Baz")
            .create_pact
          end

          let(:selectors) do
            [ UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "2") ]
          end

          let(:options) do
            { latest: true, tag: "prod", latestby: "cvp" }
          end

          it "does not allow the app to be deployed" do
            expect(subject.deployment_status_summary).to_not be_deployable
          end
        end

        describe "when deploying an app that is both a consumer and a provider to prod for the first time and the downstream provider has been deployed" do
          before do
            # Foo v1 => Bar v2
            # Bar v2 => Baz v4 (prod)
            td.create_pact_with_verification("Foo", "1", "Bar", "2")
            .use_consumer("Bar")
            .use_consumer_version("2")
            .create_provider("Baz")
            .create_pact
            .create_verification(provider_version: "4", tag_names: "prod")
          end

          let(:selectors) do
            [ UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "2") ]
          end

          # Deploy Bar v2 to prod
          let(:options) do
            { latest: true, tag: "prod", latestby: "cvp" }
          end

          it "allows the app to be deployed" do
            expect(subject.deployment_status_summary).to be_deployable
          end
        end

        describe "when deploying a provider where the pact has not been verified" do
          before do
            # Foo v1 => Bar ?
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_provider_version("2")
          end

          let(:selectors) do
            [ UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "2") ]
          end

          # Deploy Bar v2 to prod
          let(:options) do
            { latest: true, tag: "prod", latestby: "cvp" }
          end

          it "allows the app to be deployed" do
            # no integrations and no matrix rows
            expect(subject.deployment_status_summary).to be_deployable
          end
        end

        describe "when deploying a consumer where the pact has been verified, but not by the required provider version" do
          before do
            # Foo v1 => Bar v2
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_provider_version("2")
              .create_provider_version_tag("prod")
              .create_provider_version("3")
              .create_verification(comment: "the verification is not from the required provider version")
          end

          let(:selectors) do
            [ UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1") ]
          end

          # Deploy Foo v1 to prod
          let(:options) do
            { latest: true, tag: "prod", latestby: "cvp" }
          end

          # Currently returning PactNotEverVerifiedByProvider because the matrix response has changed from 'no row' to
          # 'one row with no verification details' (left outer join stuff).
          # Not sure if the 'no row' usecase can ever happen now.
          # The messages shown to the user for 'not ever verified' and 'verified by the wrong provider version'
          # are the same however, so the code does not need to be updated straight away.
          it "returns a reason indicating that the pact has not been verified by the required provider version", pending: true do
            expect(subject.deployment_status_summary.reasons.first).to be_a(PactBroker::Matrix::PactNotVerifiedByRequiredProviderVersion)
          end
        end

        describe "when two applications have pacts with each other (nureva use case)" do
          # ServiceA v 1 has been verified by ServiceB v 100
          # but ServiceB v 100 has only been verified by ServiceA v 99.
          # It's missing a verification from ServiceA v1.
          before do
            td.create_pact_with_verification("ServiceB", "100", "ServiceA", "99")
              .create_pact_with_verification("ServiceA", "1", "ServiceB", "100")
          end

          context "when both application versions are specified explictly" do
            let(:selectors) do
              [
                UnresolvedSelector.new(pacticipant_name: "ServiceA", pacticipant_version_number: "1"),
                UnresolvedSelector.new(pacticipant_name: "ServiceB", pacticipant_version_number: "100")
              ]
            end

            let(:options) { { latestby: "cvpv" } }

            it "does not allow the two apps to be deployed together" do
              expect(subject.deployment_status_summary).to_not be_deployable
            end
          end

          context "when only one application is specified" do
            let(:selectors) do
              [
                UnresolvedSelector.new(pacticipant_name: "ServiceB", pacticipant_version_number: "100")
              ]
            end

            let(:options) { { latestby: "cvp", latest: true } }

            it "does not allow the two apps to be deployed together" do
              expect(subject.deployment_status_summary).to_not be_deployable
            end
          end
        end

        describe "specifying a provider which has multiple prod versions of one consumer (explicit) and a single version of another (inferred)" do
          before do
            # Foo 1   (prod) -> Bar 2    [explicit]
            # Foo 2   (prod) -> Bar 2    [explicit]
            # Foo 3          -> Bar 2 failed [explicit]
            # Cat 20  (prod) -> Bar ?    [inferred, missing verification]
            # Dog 40         -> Bar 2 failed   [inferred, but not in prod]

            td.create_pact_with_verification("Foo", "1", "Bar", "2")
              .create_consumer_version_tag("prod")
              .create_consumer_version("2")
              .create_consumer_version_tag("prod")
              .create_pact
              .create_verification(provider_version: "2")
              .create_consumer_version("3")
              .create_pact
              .create_verification(provider_version: "2", success: false, comment: "not prod, doesn't matter")
              .create_consumer("Cat")
              .create_consumer_version("20")
              .create_consumer_version_tag("prod")
              .create_pact
              .comment("missing verification")
              .create_consumer("Dog")
              .create_consumer_version("40")
              .create_pact
              .create_verification(provider_version: "2")
          end

          let(:selector_1) { UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "2") }
          let(:selector_2) { UnresolvedSelector.new(pacticipant_name: "Foo", tag: "prod") }
          let(:selectors)  { [ selector_1, selector_2 ] }

          subject { Service.can_i_deploy(selectors, options) }

          context "with inferred selectors" do
            let(:options) { { latest: true, tag: "prod"} }

            it "determines the number of integrations" do
              expect(subject.integrations.size).to eq 3
            end

            it "finds all prod versions of Foo" do
              expect(subject.count { |row| row.consumer_name == "Foo"}).to eq 2
            end

            it "finds the single prod version of Cat" do
              expect(subject.count { |row| row.consumer_name == "Cat"}).to eq 1
            end

            it "is not deployable because of the missing verification for Cat v20" do
              expect(subject.deployment_status_summary.reasons.size).to eq 2
              expect(subject.deployment_status_summary.reasons.last).to be_a_pact_never_verified_for_consumer "Cat"
            end
          end

          context "without inferred selectors" do
            let(:options) { {} }

            it "is deployable" do
              expect(subject.deployment_status_summary).to be_deployable
            end
          end
        end

        describe "when there is a consumer with two providers, and only one of them has a verification, and the consumer and the verified provider are explicitly specified" do
          before do
            td.create_pact_with_verification("Foo", "1", "Bar", "2")
              .create_provider_version_tag("prod")
              .create_pact_with_hierarchy("Foo", "1", "Wiffle")
          end

          let(:selectors) do
            [
              UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1"),
              UnresolvedSelector.new(pacticipant_name: "Bar", tag: "prod", latest: true)
            ]
          end

          let(:options) { { latestby: "cvpv"} }

          it "should allow the consumer to be deployed" do
            expect(subject.deployment_status_summary).to be_deployable
          end
        end

        describe "when verification results are published missing tests for some interactions" do
          let(:pact_content) do
            {
              "interactions" => [
                {
                  "description" => "desc1"
                },{
                  "description" => "desc2"
                }
              ]
            }
          end

          let(:verification_tests) do
            [
              {
                "interactionDescription" => "desc1"
              }
            ]
          end

          before do
            td.create_consumer("Foo")
              .create_provider("Bar")
              .create_consumer_version
              .create_pact(json_content: pact_content.to_json)
              .create_verification(provider_version: "1", test_results: { tests: verification_tests })
          end

          let(:selectors) do
            [
              UnresolvedSelector.new(pacticipant_name: "Foo", latest: true),
              UnresolvedSelector.new(pacticipant_name: "Bar", latest: true)
            ]
          end

          let(:options) { { latestby: "cvpv"} }

          xit "should include a warning" do
            expect(subject.deployment_status_summary.reasons.last).to be_a(PactBroker::Matrix::InteractionsMissingVerifications)
          end
        end
      end
    end
  end
end
