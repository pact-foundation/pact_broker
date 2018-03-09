=begin

Things that should update the matrix (ignoring tags):
* pact created
* pact content updated
* pact deleted
* verification created
* verification deleted (not yet implemented)

It's easier to update the matrix at the resource level, so we actually update the matrix when:
* pacticipant deleted
* version deleted
* pact deleted

Things that should update the head matrix
* All of the above
* tag created
* tag deleted

=end

describe "Deleting a resource that affects the matrix" do

  let(:td) { TestDataBuilder.new }
  let(:response_body_json) { JSON.parse(subject.body) }

  subject { delete path; last_response  }

  before do
    td.create_pact_with_hierarchy("Foo", "1", "Bar")
      .create_verification(provider_version: "2")
  end

  context "deleting a pact" do
    let(:path) { "/pacts/provider/Bar/consumer/Foo/version/1" }

    it "deletes the relevant lines from the matrix" do
      expect{ subject }.to change{ PactBroker::Matrix::Row.count }.by(-1)
    end

    it "deletes the relevant lines from the head matrix" do
      expect{ subject }.to change{ PactBroker::Matrix::HeadRow.count }.by(-1)
    end
  end

  context "deleting a pacticipant" do
    let(:path) { "/pacticipants/Bar" }

    it "deletes the relevant lines from the matrix" do
      expect{ subject }.to change{ PactBroker::Matrix::Row.count }.by(-1)
    end

    it "deletes the relevant lines from the head matrix" do
      expect{ subject }.to change{ PactBroker::Matrix::HeadRow.count }.by(-1)
    end
  end

  context "deleting a version" do
    let(:path) { "/pacticipants/Foo/versions/1" }

    it "deletes the relevant lines from the matrix" do
      expect{ subject }.to change{ PactBroker::Matrix::Row.count }.by(-1)
    end

    it "deletes the relevant lines from the head matrix" do
      expect{ subject }.to change{ PactBroker::Matrix::HeadRow.count }.by(-1)
    end
  end

  context "deleting a tag" do
    before do
      td.create_consumer_version_tag("prod")
    end

    let(:path) { "/pacticipants/Foo/versions/1/tags/prod" }

    it "does not delete any lines from the matrix" do
      expect{ subject }.to change{ PactBroker::Matrix::Row.count }.by(0)
    end

    it "deletes the relevant lines from the head matrix" do
      expect{ subject }.to change{ PactBroker::Matrix::HeadRow.count }.by(-1)
    end
  end
end

describe "Creating a resource that affects the matrix" do

  let(:td) { TestDataBuilder.new }
  let(:response_body_json) { JSON.parse(subject.body) }

  subject { put(path, nil, {'CONTENT_TYPE' => 'application/json'}); last_response }

  context "creating a tag" do
    before do
      td.create_pact_with_hierarchy("Foo", "1", "Bar")
    end

    let(:path) { "/pacticipants/Foo/versions/1/tags/prod" }

    it "adds the relevant lines to the head matrix" do
      expect{ subject }.to change{ PactBroker::Matrix::HeadRow.count }.by(1)
    end

    it "does not add any lines to the matrix" do
      expect{ subject }.to change{ PactBroker::Matrix::Row.count }.by(0)
    end
  end

  context "creating a pact" do
    let(:pact_content) { load_fixture('foo-bar.json') }
    let(:path) { "/pacts/provider/Bar/consumer/Foo/versions/1.2.3" }

    subject { put path, pact_content, {'CONTENT_TYPE' => 'application/json'}; last_response }

    it "adds the relevant lines to the matrix" do
      expect{ subject }.to change{ PactBroker::Matrix::Row.count }.by(1)
    end

    it "adds the relevant lines to the head matrix" do
      expect{ subject }.to change{ PactBroker::Matrix::HeadRow.count }.by(1)
    end
  end

  context "creating a verification" do
    let(:td) { TestDataBuilder.new }
    let(:path) { "/pacts/provider/Bar/consumer/Foo/pact-version/#{pact.pact_version_sha}/verification-results" }
    let(:verification_content) { load_fixture('verification.json') }
    let(:parsed_response_body) { JSON.parse(subject.body) }
    let(:pact) { td.pact }

    subject { post path, verification_content, {'CONTENT_TYPE' => 'application/json' }; last_response  }

    before do
      td.create_pact_with_hierarchy("Foo", "1", "Bar")
    end

    it "updates the relevant lines in the matrix" do
      expect{ subject }.to change{ PactBroker::Matrix::Row.first.provider_version_number }.from(nil).to("4.5.6")
    end

    it "updates the relevant lines in the head matrix" do
      expect{ subject }.to change{ PactBroker::Matrix::HeadRow.first.provider_version_number }.from(nil).to("4.5.6")
    end
  end
end
