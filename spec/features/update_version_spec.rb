describe "Updating a pacticipant version" do
  let(:path) { "/pacticipants/Foo/versions/1234" }
  let(:headers) { { 'CONTENT_TYPE' => content_type } }
  let(:content_type) { 'application/merge-patch+json' }
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
        expect(response_body[:branch]).to eq "original-branch"
        expect(response_body[:buildUrl]).to eq "new-build-url"
      end

      context "when the same not null branch is specified" do
        let(:version_hash) { { branch: "original-branch" } }

        its(:status) { is_expected.to eq 200 }
      end

      context "when the existing version has a branch, and the new branch is different" do
        let(:version_hash) { { branch: "new-branch" } }

        its(:status) { is_expected.to eq 409 }

        it "returns an error" do
          expect(response_body[:errors][:branch].first).to include "cannot be changed"
        end
      end

      context "when the existing version has a branch, and the new branch is nil" do
        let(:version_hash) { { branch: nil } }

        its(:status) { is_expected.to eq 409 }

        it "returns an error" do
          expect(response_body[:errors][:branch].first).to include "cannot be changed"
        end
      end

      context "when the existing version does not have a branch, and the new branch is specified" do
        let(:original_branch) { nil }

        its(:status) { is_expected.to eq 200 }
      end

      context "when the existing version does not have a branch, and the new branch is also nil" do
        let(:original_branch) { nil }
        let(:version_hash) { { branch: nil } }

        its(:status) { is_expected.to eq 200 }
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
      let(:content_type) { 'application/json' }

      its(:status) { is_expected.to eq 415 }
    end

    context "when using a PUT with application/merge-patch+json" do
      subject { put(path, version_hash.to_json, headers) }

      its(:status) { is_expected.to eq 415 }
    end
  end

  context "with a PUT" do
    let(:content_type) { 'application/json' }

    subject { put(path, version_hash.to_json, headers) }

    context "when the version already exists" do
      before do
        td.subtract_day
          .create_consumer("Foo")
          .create_consumer_version("1234", branch: "original-branch", build_url: "original-build-url")
          .create_consumer_version_tag("dev")
      end

      context "when the branch is attempted to be changed" do
        let(:version_hash) { { branch: "new-branch" } }

        its(:status) { is_expected.to eq 409 }
      end

      context "when the branch is not attempted to be changed" do
        let(:version_hash) { { branch: "original-branch" } }

        it "overwrites the direct properties and blanks out any unprovided ones" do
          expect(response_body[:branch]).to eq "original-branch"
          expect(response_body).to_not have_key(:buildUrl)
        end
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
