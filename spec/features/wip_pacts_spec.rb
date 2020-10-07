RSpec.describe "the lifecycle of a WIP pact" do
  let(:pact_content_1) { { interactions: [{ some: 'interaction'}] }.to_json }
  let(:pact_content_2) { { interactions: [{ some: 'other interaction'}] }.to_json }
  let(:pact_content_3) { { interactions: [{ some: 'other other interaction'}] }.to_json }
  let(:request_headers) { { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/hal+json"} }
  let(:provider_version_number) { "2" }
  let(:pacts_for_verification_request_body) do
    {
      consumerVersionSelectors: [ { tag: "master", latest: true } ],
      providerVersionTags: ["master"],
      includeWipPactsSince: start_date
    }.to_json
  end

  let(:start_date) { (Date.today - 1).to_datetime }

  def create_initial_provider_version_on_master
    td.set_now(DateTime.now - 100)
      .create_provider("Bar")
      .create_provider_version("1")
      .create_provider_version_tag("master")
  end

  def can_i_merge(consumer_version)
    can_i_deploy(consumer_version, "master")
  end

  def can_i_deploy(consumer_version, provider_tag)
    can_i_deploy_response = get("/can-i-deploy", { pacticipant: "Foo", version: consumer_version, to: provider_tag })
    JSON.parse(can_i_deploy_response.body)["summary"]["deployable"]
  end

  def publish_pact_with_master_tag
    put("/pacts/provider/Bar/consumer/Foo/version/1", pact_content_1, request_headers)
    put("/pacticipants/Foo/versions/1/tags/master", nil, request_headers)
  end

  def publish_pact_with_feature_tag(version = "2", tag = "feat-x", pact_content = nil)
    put("/pacts/provider/Bar/consumer/Foo/version/#{version}", pact_content || pact_content_2, request_headers)
    put("/pacticipants/Foo/versions/#{version}/tags/#{tag}", nil, request_headers)
  end

  def publish_new_pact_with_master_tag_after_merging_in_feature_branch
    put("/pacts/provider/Bar/consumer/Foo/version/3", pact_content_2, request_headers)
    put("/pacticipants/Foo/versions/2/tags/master", nil, request_headers)
  end

  def get_pacts_for_verification(request_body = nil)
    post("/pacts/provider/Bar/for-verification", request_body || pacts_for_verification_request_body, request_headers)
  end

  def pact_urls_from(pacts_for_verification_response)
    JSON.parse(pacts_for_verification_response.body)["_embedded"]["pacts"].collect do | pact |
      pact["_links"]["self"]["href"]
    end
  end

  def wip_pact_url_from(pacts_for_verification_response)
    wip_pacts_from(pacts_for_verification_response).first["_links"]["self"]["href"]
  end

  def get_pact(pact_url)
    get(pact_url, nil, request_headers)
  end

  def verification_results_url_from(pact_response)
    JSON.parse(pact_response.body)["_links"]["pb:publish-verification-results"]["href"]
  end

  def publish_verification_results_with_tag_master(verification_results_url, success)
    publish_verification_results(provider_version_number, "master", verification_results_url, success)
  end

  def publish_verification_results(provider_version_number, tag, verification_results_url, success)
    request_body = { success: success, providerApplicationVersion: provider_version_number}.to_json
    post(verification_results_url, request_body, request_headers)
    put("/pacticipants/Bar/versions/#{provider_version_number}/tags/#{tag}", nil, request_headers)
  end

  def pending_status_from(pacts_for_verification_response)
    JSON.parse(pacts_for_verification_response.body)["_embedded"]["pacts"][0]["verificationProperties"]["pending"]
  end

  def wip_pacts_from(pacts_for_verification_response)
    JSON.parse(pacts_for_verification_response.body)["_embedded"]["pacts"].select do | pact |
      pact["verificationProperties"]["wip"]
    end
  end

  def build_pacts_for_verification_request_body(provider_version_tag, consumer_version_tag = nil)
    {
      consumerVersionSelectors: [ { tag: consumer_version_tag || provider_version_tag, latest: true, fallbackTag: "master" } ],
      providerVersionTags: [provider_version_tag],
      includeWipPactsSince: start_date
    }.to_json
  end

  context "when the includeWipPactsSince date is specified" do
    context "a pact published afer the specified date, with a tag that is not specified explictly in the 'pacts for verification' request" do
      describe "when it is first published" do
        it "is included in the list of pacts to verify as a WIP pact" do
          create_initial_provider_version_on_master

          publish_pact_with_master_tag
          publish_pact_with_feature_tag

          pacts_for_verification_response = get_pacts_for_verification
          expect(wip_pacts_from(pacts_for_verification_response).size).to eq 1
        end
      end

      describe "when it is verified unsuccessfully" do
        it "is still included as a WIP pact" do
          create_initial_provider_version_on_master

          # CONSUMER BUILD
          # publish pact
          publish_pact_with_master_tag
          publish_pact_with_feature_tag

          # PROVIDER BUILD
          # fetch pacts to verify
          pacts_for_verification_response = get_pacts_for_verification
          pact_url = wip_pact_url_from(pacts_for_verification_response)
          pact_response = get_pact(pact_url)

          # verify pact... failure...

          # publish failure verification results
          verification_results_url = verification_results_url_from(pact_response)
          publish_verification_results_with_tag_master(verification_results_url, false)

          # ANOTHER PROVIDER BUILD
          # get pacts for verification
          pacts_for_verification_response = get_pacts_for_verification
          # still pending
          expect(wip_pacts_from(pacts_for_verification_response).size).to eq 1
        end
      end

      describe "when it is verified successfully while included as a WIP pact" do
        it "is still included as a WIP pact" do
          create_initial_provider_version_on_master

          # CONSUMER BUILD
          publish_pact_with_master_tag
          publish_pact_with_feature_tag

          # PROVIDER BUILD
          # fetch pacts to verify
          pacts_for_verification_response = get_pacts_for_verification
          pact_url = wip_pact_url_from(pacts_for_verification_response)
          pact_response = get_pact(pact_url)

          # verify pact... success!

          # publish success verification results
          verification_results_url = verification_results_url_from(pact_response)
          publish_verification_results_with_tag_master(verification_results_url, true)

          # ANOTHER PROVIDER BUILD 2
          # get pacts for verification
          # publish successful verification results
          pacts_for_verification_response = get_pacts_for_verification
          # still wip
          expect(wip_pacts_from(pacts_for_verification_response).size).to eq 1
        end
      end

      describe "when it is verified successfully when included explicitly" do
        it "is no longer included as a WIP pact" do
          create_initial_provider_version_on_master

          # CONSUMER BUILD
          publish_pact_with_master_tag
          publish_pact_with_feature_tag

          # PROVIDER BUILD
          # fetch pacts to verify
          pacts_for_verification_response = get_pacts_for_verification
          pact_url = wip_pact_url_from(pacts_for_verification_response)
          pact_response = get_pact(pact_url)

          # verify pact... success!

          # publish success verification results
          verification_results_url = verification_results_url_from(pact_response)
          publish_verification_results_with_tag_master(verification_results_url, true)

          # CONSUMER BUILD
          # merge feature branch into master
          publish_new_pact_with_master_tag_after_merging_in_feature_branch

          # ANOTHER PROVIDER BUILD 3
          # get pacts for verification
          # publish successful verification results
          pacts_for_verification_response = get_pacts_for_verification
          # no longer wip
          expect(wip_pacts_from(pacts_for_verification_response).size).to eq 0
        end
      end

      describe "a feature branching scenario" do
        it "keeps being WIP until the branch is merged" do
          create_initial_provider_version_on_master

          # CONSUMER BUILD - master
          publish_pact_with_master_tag

          # CONSUMER BUILD - feature branch
          publish_pact_with_feature_tag
          expect(can_i_merge("2")).to_not be true

          # PROVIDER BUILD
          # fetch pacts to verify
          pacts_for_verification_response = get_pacts_for_verification
          pact_url = wip_pact_url_from(pacts_for_verification_response)
          pact_response = get_pact(pact_url)

          # verify pact... success!

          # publish success verification results
          verification_results_url = verification_results_url_from(pact_response)
          publish_verification_results("1", "master", verification_results_url, true)

          # CONSUMER
          expect(can_i_merge("2")).to be true

          # ANOTHER PROVIDER BUILD before the consumer build runs again
          # fetch pacts to verify
          pacts_for_verification_response = get_pacts_for_verification
          # feat-x pact is still wip
          pact_url = wip_pact_url_from(pacts_for_verification_response)
          pact_response = get_pact(pact_url)

          # however feat-x pact is no longer pending because it has a successful verification from master!!!
          # Question: do we want this behaviour? Or should pending use the same logic?
          expect(wip_pacts_from(pacts_for_verification_response).first['verificationProperties']['wip']).to be true
          expect(wip_pacts_from(pacts_for_verification_response).first['verificationProperties']['pending']).to be nil

          # verify pact... success!

          # publish success verification results
          verification_results_url = verification_results_url_from(pact_response)
          publish_verification_results("2", "master", verification_results_url, true)

          # CONSUMER BUILD
          # merge feature branch into master
          expect(can_i_merge("2")).to be true
          publish_new_pact_with_master_tag_after_merging_in_feature_branch
          expect(can_i_deploy("3", "master")).to be true

          # ANOTHER PROVIDER BUILD 3
          # get pacts for verification
          # publish successful verification results
          pacts_for_verification_response = get_pacts_for_verification
          # no longer wip
          expect(wip_pacts_from(pacts_for_verification_response).size).to eq 0
        end
      end

      describe "a feature branching scenario with matching feature branches" do
        it "stays wip on master even after it has been successfully verified on the provider's feature branch" do
          create_initial_provider_version_on_master

          # CONSUMER BUILD - master
          publish_pact_with_master_tag

          # CONSUMER BUILD - feature branch
          publish_pact_with_feature_tag

          # PROVIDER BUILD - master
          # fetch pacts to verify
          pacts_for_verification_response = get_pacts_for_verification(build_pacts_for_verification_request_body("master"))
          pact_url = wip_pact_url_from(pacts_for_verification_response)
          pact_response = get_pact(pact_url)

          # verify pact... failure (not implemented on master yet)

          # publish failure verification results
          verification_results_url = verification_results_url_from(pact_response)
          publish_verification_results("1", "master", verification_results_url, false)

          # PROVIDER BUILD - on a matching feature branch
          # fetch pacts to verify
          pacts_for_verification_response = get_pacts_for_verification(build_pacts_for_verification_request_body("feat-x"))
          # pact is not WIP because it has been explicitly included
          expect(wip_pacts_from(pacts_for_verification_response).size).to eq 0
          pact_url = pact_urls_from(pacts_for_verification_response).first
          pact_response = get_pact(pact_url)

          # verify pact - success on feature branch!

          # publish successful results from feature branch
          verification_results_url = verification_results_url_from(pact_response)
          publish_verification_results("2", "feat-x", verification_results_url, true)

          # PROVIDER BUILD - back on master
          pacts_for_verification_response = get_pacts_for_verification(build_pacts_for_verification_request_body("master"))
          # still wip for master
          expect(wip_pacts_from(pacts_for_verification_response).size).to eq 1
        end
      end

      describe "when a brand new provider branch is created" do
        it "does not include any previously created WIP pacts because every single pact is pending for this new branch, and we don't want to verify the world" do
          create_initial_provider_version_on_master

          # CONSUMER BUILD - master
          publish_pact_with_master_tag

          # CONSUMER BUILD - feature branch
          publish_pact_with_feature_tag

          # PROVIDER BUILD - brand new feature branch
          pacts_for_verification_response = get_pacts_for_verification(build_pacts_for_verification_request_body("feat-y", "master"))
          expect(wip_pacts_from(pacts_for_verification_response).size).to eq 0

          # verify master pact successfully
          pact_url = pact_urls_from(pacts_for_verification_response).first
          pact_response = get_pact(pact_url)

          # publish successful results from feature branch
          verification_results_url = verification_results_url_from(pact_response)
          publish_verification_results("2", "feat-y", verification_results_url, true)

          # PROVIDER BUILD 2 - feature branch
          pacts_for_verification_response = get_pacts_for_verification(build_pacts_for_verification_request_body("feat-y", "master"))
          # still no wip pacts
          expect(wip_pacts_from(pacts_for_verification_response).size).to eq 0
        end

        it "does include any subsequently created new pacts" do
          create_initial_provider_version_on_master

          # CONSUMER BUILD - master
          publish_pact_with_master_tag

          # CONSUMER BUILD - feature branch
          publish_pact_with_feature_tag

          # PROVIDER BUILD - brand new feature branch
          pacts_for_verification_response = get_pacts_for_verification(build_pacts_for_verification_request_body("feat-y", "master"))
          expect(wip_pacts_from(pacts_for_verification_response).size).to eq 0
          # verify master pact successfully (creates a new provider version with tag feat-y)
          pact_url = pact_urls_from(pacts_for_verification_response).first
          pact_response = get_pact(pact_url)
          verification_results_url = verification_results_url_from(pact_response)
          publish_verification_results("2", "feat-y", verification_results_url, true)
          sleep 1 if ::DB.mysql? # time resolution is lower on MySQL, need to make sure the next pacts are created after the above provider version

          # CONSUMER BUILD - feature branch again
          # republish same pact content with new version
          publish_pact_with_feature_tag("3")

          # CONSUMER BUILD - another feature branch
          publish_pact_with_feature_tag("4", "feat-z", pact_content_3)

          # PROVIDER BUILD - brand new feature branch again
          pacts_for_verification_response = get_pacts_for_verification(build_pacts_for_verification_request_body("feat-y", "master"))
          expect(wip_pacts_from(pacts_for_verification_response).size).to eq 2
        end
      end
    end
  end
end
