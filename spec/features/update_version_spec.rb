describe "Updating a pacticipant version" do
  let(:path) { "/pacticipants/Foo/versions/1234" }
  let(:headers) { { "CONTENT_TYPE" => content_type } }
  let(:content_type) { "application/merge-patch+json" }
  let(:response_body) { JSON.parse(subject.body, symbolize_names: true)}
  let(:version_hash) do
    {
      buildUrl: "http://build"
    }
  end

  context "with a PATCH" do
    subject { patch(path, version_hash.to_json, headers) }

    context "when the version already exists" do
      before do
        td.subtract_day
          .create_consumer("Foo")
          .create_consumer_version("1234", branch: original_branch, build_url: "original-build-url")
          .create_consumer_version_tag("dev")
      end
      let(:original_branch) { "original-branch" }

      let(:version_hash) { { buildUrl: "new-build-url" } }

      it "returns a 200" do
        expect(subject.status).to be 200
      end

      it "does not overwrites any properties that weren't specified" do
        expect(response_body[:buildUrl]).to eq "new-build-url"
      end

      context "when no tags are specified" do
        it "does not change the tags" do
          expect { subject }.to_not change { PactBroker::Domain::Version.for("Foo", "1234").tags }
        end
      end

      context "when tags are specified" do
        let(:version_hash) { { tags: [ { name: "main" }] } }

        it "overwrites the tags" do
          expect(response_body[:_embedded][:tags].size).to eq 1
          expect(response_body[:_embedded][:tags].first[:name]).to eq "main"
        end
      end

      it "does not change the created date" do
        expect { subject }.to_not change { PactBroker::Domain::Version.for("Foo", "1234").created_at }
      end
    end

    context "when using a PATCH with application/json" do
      let(:content_type) { "application/json" }

      its(:status) { is_expected.to eq 415 }
    end

    context "when using a PUT with application/merge-patch+json" do
      subject { put(path, version_hash.to_json, headers) }

      its(:status) { is_expected.to eq 415 }
    end
  end

  context "with a PUT" do
    let(:content_type) { "application/json" }

    subject { put(path, version_hash.to_json, headers) }

    context "when the version already exists" do
      before do
        td.subtract_day
          .create_consumer("Foo")
          .create_consumer_version("1234", branch: "original-branch", build_url: "original-build-url")
          .create_consumer_version_tag("dev")
      end

      context "when no tags are specified" do
        it "does not change the tags" do
          expect { subject }.to_not change { PactBroker::Domain::Version.for("Foo", "1234").tags }
        end
      end

      context "when tags are specified" do
        let(:version_hash) { { branch: "original-branch", tags: [ { name: "main" }] } }

        it "overwrites the tags" do
          expect(response_body[:_embedded][:tags].size).to eq 1
          expect(response_body[:_embedded][:tags].first[:name]).to eq "main"
        end
      end

      it "does not change the created date" do
        expect { subject }.to_not change { PactBroker::Domain::Version.for("Foo", "1234").created_at }
      end
    end
  end
end
