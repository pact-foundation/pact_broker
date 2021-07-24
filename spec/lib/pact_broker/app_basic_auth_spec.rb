require "pact_broker/app"
require "anyway/testing/helpers"

module PactBroker
  describe App do
    include Anyway::Testing::Helpers

    before do
      allow(PactBroker::DB).to receive(:run_migrations)
    end

    class TestApp2 < PactBroker::App
      def configure_database_connection
        # do nothing so we don't screw up our test connection
      end
    end

    around do | example |
      env_vars = {
        "PACT_BROKER_BASIC_AUTH_ENABLED" => basic_auth_enabled,
        "PACT_BROKER_BASIC_AUTH_USERNAME" => basic_auth_username,
        "PACT_BROKER_BASIC_AUTH_PASSWORD" => basic_auth_password,
        "PACT_BROKER_BASIC_AUTH_READ_ONLY_USERNAME" => basic_auth_read_only_username,
        "PACT_BROKER_BASIC_AUTH_READ_ONLY_PASSWORD" => basic_auth_read_only_password,
        "PACT_BROKER_ALLOW_PUBLIC_READ" => allow_public_read,
        "PACT_BROKER_ENABLE_PUBLIC_BADGE_ACCESS" => enable_public_badge_access
      }
      with_env(env_vars, &example)
    end

    let(:basic_auth_enabled) { "true" }
    let(:basic_auth_username) { "user" }
    let(:basic_auth_password) { "pass" }
    let(:basic_auth_read_only_username) { "rouser" }
    let(:basic_auth_read_only_password) { "ropass" }
    let(:allow_public_read) { "false" }
    let(:enable_public_badge_access) { "false" }

    let(:app) do
      TestApp2.new do | configuration |
        configuration.database_connection = PactBroker::DB.connection
      end
    end

    subject { get("/") }

    context "with correct write credentials" do
      before do
        basic_authorize "user", "pass"
      end

      its(:status) { is_expected.to eq 200 }
    end

    context "with correct read credentials" do
      before do
        basic_authorize "rouser", "ropass"
      end

      its(:status) { is_expected.to eq 200 }
    end

    context "with incorrect credentials" do
      before do
        basic_authorize "wrong", "pass"
      end

      its(:status) { is_expected.to eq 401 }
    end

    context "with no credentials" do
      its(:status) { is_expected.to eq 401 }

      context "when allow_public_read=true" do
        let(:allow_public_read) { "true" }

        its(:status) { is_expected.to eq 200 }
      end
    end

    context "with basic auth enabled but no username or password configured" do
      before do
        basic_authorize "", ""
      end

      let(:basic_auth_username) { "" }
      let(:basic_auth_password) { "" }

      its(:status) { is_expected.to eq 401 }
    end

    context "with basic auth disabled" do
      let(:basic_auth_enabled) { "false" }

      context "with no credentials" do
        its(:status) { is_expected.to eq 200 }
      end
    end

    context "accessing a badge" do
      before do
        td.create_pact_with_hierarchy("foo", "1", "bar")
      end

      subject { get(PactBroker::Api::PactBrokerUrls.badge_url_for_latest_pact(td.and_return(:pact))) }

      its(:status) { is_expected.to eq 401 }

      context "with no basic auth configured" do
        let(:basic_auth_enabled) { "false" }

        its(:status) { is_expected.to eq 307 }
      end

      context "with public badge access enabled" do
        let(:enable_public_badge_access) { "true" }

        its(:status) { is_expected.to eq 307 }
      end
    end
  end
end
