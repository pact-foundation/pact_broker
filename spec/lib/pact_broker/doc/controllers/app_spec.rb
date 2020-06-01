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

            context "with the base_url not set" do
              it "returns relative links" do
                expect(subject.body).to include "href='/css"
              end
            end

            context "with the base_url set" do
              before do
                allow(PactBroker.configuration).to receive(:base_url).and_return('http://example.org/pact-broker')
              end

              it "returns absolute links" do
                expect(subject.body).to include "href='http://example.org/pact-broker/css"
              end
            end
          end

          context "when the resource does not exist" do
            subject { get "/blah" }

            it "returns a 200 status, because otherwise, the Rack cascade will make it return a 404 from the webmachine API" do
              subject
              expect(last_response.status).to eq 200
            end

            it "returns a html content type" do
              subject
              expect(last_response.headers['Content-Type']).to eq "text/html;charset=utf-8"
            end

            it "returns a custom error page" do
              subject
              expect(last_response.body).to include "No documentation exists"
            end
          end

          context "when the resource has a context and there is a folder with a matching name" do
            subject { get "/diff?context=pact" }

            it "returns documentation in a folder of the matching name" do
              subject
              expect(last_response.status).to eq 200
              expect(last_response.body).to include "Diff"
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