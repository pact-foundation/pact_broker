require 'pact_broker/doc/controllers/app'

module PactBroker
  module Doc
    module Controllers
      describe App do

        describe "GET relation" do

          let(:app) { PactBroker::Doc::Controllers::App }

          context "when the resource exists" do
            subject { get "/webhooks" }

            it "returns a 200 status" do
              subject
              expect(last_response.status).to eq 200
            end

            it "returns a html content type" do
              subject
              expect(last_response.headers['Content-Type']).to eq "text/html;charset=utf-8"
            end

            it "returns a html body" do
              subject
              expect(last_response.body).to include "<html>"
            end
          end

          context "when the resource does not exist" do
            subject { get "/blah" }

            it "returns a 404 status" do
              subject
              expect(last_response.status).to eq 404
            end

            it "returns a html content type" do
              subject
              expect(last_response.headers['Content-Type']).to eq "text/html;charset=utf-8"
            end

          end
        end

      end
    end
  end
end