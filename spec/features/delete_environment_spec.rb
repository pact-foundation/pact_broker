describe "Deleting an environment" do
  before do
    td.create_environment("test")
  end

  let(:path) { "/environments/test" }

  subject { delete(path, nil) }

  it "returns a 204 response" do
    subject
    expect(last_response.status).to be 204
  end
end
