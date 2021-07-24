require "pact_broker/api/middleware/basic_auth"
require "pact_broker/api/authorization/resource_access_policy"

module PactBroker
  module Api
    module Middleware
      describe "basic auth" do
        let(:protected_app) { ->(_) { [200, {}, []]} }

        let(:policy) { PactBroker::Api::Authorization::ResourceAccessPolicy.build(allow_public_read_access, allow_public_access_to_heartbeat) }
        let(:app) { BasicAuth.new(protected_app, [write_username, write_password], [read_username, read_password], policy) }
        let(:allow_public_read_access) { false }
        let(:write_username) { "write_username" }
        let(:write_password) { "write_password" }
        let(:read_username) { "read_username" }
        let(:read_password) { "read_password" }
        let(:allow_public_access_to_heartbeat) { true }

        context "when requesting the heartbeat" do
          let(:path) { "/diagnostic/status/heartbeat" }

          context "when allow_public_access_to_heartbeat is true" do
            context "when no credentials are used" do
              it "allows GET" do
                get path
                expect(last_response.status).to eq 200
              end
            end
          end

          context "when allow_public_access_to_heartbeat is false" do
            let(:allow_public_access_to_heartbeat) { false }

            context "when no credentials are used" do
              it "does not allow GET" do
                get path
                expect(last_response.status).to eq 401
              end
            end

            context "when the correct credentials are used" do
              it "allows GET" do
                basic_authorize "read_username", "read_password"
                get path
                expect(last_response.status).to eq 200
              end
            end
          end
        end

        context "when requesting a pact badge" do
          context "when no credentials are used" do
            it "allows GET" do
              get "/pacts/provider/foo/consumer/bar/badge"
              expect(last_response.status).to eq 200
            end
          end
        end

        context "when requesting a matrix badge" do
          context "when no credentials are used" do
            it "allows GET" do
              get "/matrix/provider/foo/latest/dev/consumer/bar/latest/dev/badge"
              expect(last_response.status).to eq 200
            end
          end
        end

        context "with the correct username and password for the write user" do
          it "allows GET" do
            basic_authorize "write_username", "write_password"
            get "/"
            expect(last_response.status).to eq 200
          end

          it "allows POST" do
            basic_authorize "write_username", "write_password"
            post "/"
            expect(last_response.status).to eq 200
          end

          it "allows HEAD" do
            basic_authorize "write_username", "write_password"
            head "/"
            expect(last_response.status).to eq 200
          end

          it "allows OPTIONS" do
            basic_authorize "write_username", "write_password"
            options "/"
            expect(last_response.status).to eq 200
          end

          it "allows PUT" do
            basic_authorize "write_username", "write_password"
            delete "/"
            expect(last_response.status).to eq 200
          end

          it "allows PATCH" do
            basic_authorize "write_username", "write_password"
            patch "/"
            expect(last_response.status).to eq 200
          end

          it "allows DELETE" do
            basic_authorize "write_username", "write_password"
            delete "/"
            expect(last_response.status).to eq 200
          end
        end

        context "with the incorrect username for the write user" do
          it "does not allow POST" do
            basic_authorize "wrong_username", "write_password"
            post "/"
            expect(last_response.status).to eq 401
          end
        end

        context "with the incorrect password for the write user" do
          it "does not allow POST" do
            basic_authorize "write_username", "wrong_password"
            post "/"
            expect(last_response.status).to eq 401
          end
        end

        context "with the correct username and password for the read user" do
          it "allows GET" do
            basic_authorize "read_username", "read_password"
            get "/"
            expect(last_response.status).to eq 200
          end

          it "allows OPTIONS" do
            basic_authorize "read_username", "read_password"
            options "/"
            expect(last_response.status).to eq 200
          end

          it "allows HEAD" do
            basic_authorize "read_username", "read_password"
            head "/"
            expect(last_response.status).to eq 200
          end

          it "does not allow POST" do
            basic_authorize "read_username", "read_password"
            post "/"
            expect(last_response.status).to eq 401
          end

          it "does not allow PUT" do
            basic_authorize "read_username", "read_password"
            put "/"
            expect(last_response.status).to eq 401
          end

          it "does not allow PATCH" do
            basic_authorize "read_username", "read_password"
            patch "/"
            expect(last_response.status).to eq 401
          end

          it "does not allow DELETE" do
            basic_authorize "read_username", "read_password"
            delete "/"
            expect(last_response.status).to eq 401
          end

          it "allows POST to the pacts for verification endpoint" do
            basic_authorize "read_username", "read_password"
            post "/pacts/provider/Foo/for-verification"
            expect(last_response.status).to eq 200
          end
        end

        context "with the incorrect username and password for the write user" do
          it "does not allow GET" do
            basic_authorize "write_username", "wrongpassword"
            get "/"
            expect(last_response.status).to eq 401
          end
        end

        context "with the incorrect username and password for the read user" do
          it "does not allow GET" do
            basic_authorize "read_username", "wrongpassword"
            get "/"
            expect(last_response.status).to eq 401
          end
        end

        context "with a request to the badge URL" do
          context "with no credentials" do
            it "allows GET" do
              get "/pacts/provider/foo/consumer/bar/badge"
              expect(last_response.status).to eq 200
            end
          end
        end

        context "when there is no read only user configured" do
          before do
            allow($stdout).to receive(:puts)
          end

          let(:read_username) { nil }
          let(:read_password) { nil }

          context "when allow_public_read_access is false" do
            context "with no credentials" do
              it "does not allow a GET" do
                get "/"
                expect(last_response.status).to eq 401
              end
            end

            context "with empty credentials" do
              it "does not allow a GET" do
                basic_authorize("", "")
                get "/"
                expect(last_response.status).to eq 401
              end
            end

            context "with incorrect credentials" do
              it "does not allow a GET" do
                basic_authorize("foo", "bar")
                get "/"
                expect(last_response.status).to eq 401
              end
            end
          end

          context "when allow_public_read_access is true" do
            let(:allow_public_read_access) { true }

            context "with no credentials" do
              it "allows a GET" do
                get "/"
                expect(last_response.status).to eq 200
              end

              it "does not allow POST" do
                post "/"
                expect(last_response.status).to eq 401
              end
            end

            context "with empty credentials" do
              before do
                basic_authorize("", "")
              end

              it "allows a GET" do
                get "/"
                expect(last_response.status).to eq 200
              end

              it "does not allow POST" do
                post "/"
                expect(last_response.status).to eq 401
              end
            end

            context "with incorrect credentials" do
              before do
                basic_authorize("foo", "bar")
              end

              it "allows a GET" do
                get "/"
                expect(last_response.status).to eq 200
              end

              it "does not allow POST" do
                post "/"
                expect(last_response.status).to eq 401
              end
            end
          end
        end

        context "when the credentials are configured with empty strings" do
          before do
            basic_authorize("", "")
          end

          let(:write_username) { "" }
          let(:write_password) { "" }

          subject { get("/") }

          its(:status) { is_expected.to eq 401 }
        end
      end
    end
  end
end
