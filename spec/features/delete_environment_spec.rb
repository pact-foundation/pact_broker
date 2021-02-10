describe "Deleting an environment" do
  before do
    td.create_environment("test", uuid: "1234")
  end

  let(:path) { "/environments/1234" }

  subject { delete(path, nil) }

  it "returns a 204 response" do
    subject
    expect(last_response.status).to be 204
  end
end
