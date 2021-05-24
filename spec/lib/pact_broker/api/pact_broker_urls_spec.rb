require 'pact_broker/api/pact_broker_urls'

module PactBroker
  module Api
    describe PactBrokerUrls do
      before do
        allow(PactBrokerUrls).to receive(:logger).and_return(logger)
      end
      let(:logger) { double('logger').as_null_object }

      # Regex find all the URL parameter names
      # \/\{[^\}\s\[\(\.]+\}

      let(:base_url) { "http://example.org" }
      let(:consumer_name) { "Foo/Foo" }
      let(:provider_name) { "Bar/Bar" }
      let(:pact) do
        double('pact',
          consumer: consumer,
          provider: provider,
          consumer_version_number: "123/456",
          pact_version_sha: "5hbfu",
          consumer_version_tag_names: ["dev"])
      end
      let(:consumer) { double('pacticipant', name: consumer_name) }
      let(:provider) { double('pacticipant', name: provider_name) }
      let(:verification) do
        instance_double(PactBroker::Domain::Verification,
          consumer_name: consumer_name,
          provider_name: provider_name,
          pact_version_sha: "1234",
          number: "1")
      end
      let(:version) do
        double('version',
          pacticipant: consumer,
          number: "2/4")
      end
      let(:tag) { double('tag', name: "feat/foo", version: version) }

      matcher :match_route_in_api do |api|
        match do |url|
          req = Webmachine::Request.new("GET", URI(url), Webmachine::Headers.new, "", nil)
          api.application.routes.any?{ |route| route.match?(req) }
        end

        description do
          "match route in API"
        end

        failure_message do |_|
          "expected API to have route for path #{URI.parse(url).path}"
        end

        failure_message_when_negated do |_|
          "expected API to not have route for path #{URI.parse(url).path}"
        end
      end

      describe "pact_url" do
        subject { PactBrokerUrls.pact_url(base_url, pact) }

        it { is_expected.to match_route_in_api(PactBroker::API) }
        it { is_expected.to eq "http://example.org/pacts/provider/Bar%2FBar/consumer/Foo%2FFoo/version/123%2F456" }
      end

      describe "templated_tag_url_for_pacticipant" do
        subject { PactBrokerUrls.templated_tag_url_for_pacticipant(provider_name, base_url) }

        it { is_expected.to eq "http://example.org/pacticipants/Bar%2FBar/versions/{version}/tags/{tag}" }
      end

      describe "pact_triggered_webhooks_url" do
        subject { PactBrokerUrls.pact_triggered_webhooks_url(pact, base_url) }

        it { is_expected.to match_route_in_api(PactBroker::API) }
        it { is_expected.to eq "http://example.org/pacts/provider/Bar%2FBar/consumer/Foo%2FFoo/version/123%2F456/triggered-webhooks" }
      end

      describe "verification_triggered_webhooks_url" do
        subject { PactBrokerUrls.verification_triggered_webhooks_url(verification, base_url) }

        it { is_expected.to match_route_in_api(PactBroker::API) }
        it { is_expected.to eq "http://example.org/pacts/provider/Bar%2FBar/consumer/Foo%2FFoo/pact-version/1234/verification-results/1/triggered-webhooks" }
      end

      describe "verification_publication_url" do
        context "with no metadata" do
          subject { PactBrokerUrls.verification_publication_url(verification, base_url) }

          it { is_expected.to match_route_in_api(PactBroker::API) }
          it { is_expected.to eq "http://example.org/pacts/provider/Bar%2FBar/consumer/Foo%2FFoo/pact-version/1234/metadata//verification-results" }
        end

        context "with metadata" do
          subject { PactBrokerUrls.verification_publication_url(verification, base_url, "abcd") }

          it { is_expected.to match_route_in_api(PactBroker::API) }
          it { is_expected.to eq "http://example.org/pacts/provider/Bar%2FBar/consumer/Foo%2FFoo/pact-version/1234/metadata/abcd/verification-results" }
        end
      end

      describe "templated_diff_url" do
        subject { PactBrokerUrls.templated_diff_url(pact, base_url) }

        it { is_expected.to eq "http://example.org/pacts/provider/Bar%2FBar/consumer/Foo%2FFoo/pact-version/5hbfu/diff/pact-version/{pactVersion}" }
      end

      describe "webhook metadata" do
        it "builds the webhook metadata" do
          encoded_metadata = PactBrokerUrls.encode_metadata("some" => "metadata")
          expect(PactBrokerUrls.decode_pact_metadata(encoded_metadata)).to eq "some" => "metadata"
        end
      end

      describe "decode_pact_metadata" do
        context "when the metadata is nil" do
          it "returns an empty hash" do
            expect(PactBrokerUrls.decode_pact_metadata(nil)).to eq({})
          end
        end

        context "when the metadata is empty" do
          it "returns an empty hash" do
            expect(PactBrokerUrls.decode_pact_metadata("")).to eq({})
          end
        end

        context "with padding" do
          let(:encoded_metadata) { Base64.urlsafe_encode64("foo=bar", padding: true) }

          it "can still handle it" do
            expect(PactBrokerUrls.decode_pact_metadata(encoded_metadata)).to eq("foo" => "bar")
          end
        end

        context "when the padding has been removed" do
          let(:encoded_metadata) { Base64.urlsafe_encode64("foo=bar", padding: false) }

          it "can still handle it" do
            expect(PactBrokerUrls.decode_pact_metadata(encoded_metadata)).to eq("foo" => "bar")
          end
        end

        context "another example without the padding" do
          let(:encoded_metadata) { "c1tdW2xdPXRydWUmc1tdW2" }

          it "can still handle it" do
            expect(PactBrokerUrls.decode_pact_metadata(encoded_metadata)).to eq({ "s" => [{ "l" => "true" }, nil] })
          end
        end

        context "when the metadata is not valid base64" do
          let(:encoded_metadata) { "%" }

          before { allow(Base64).to receive(:decode64).and_raise(ArgumentError) }

          it "returns an empty hash" do
            expect(PactBrokerUrls.decode_pact_metadata(encoded_metadata)).to eq({})
          end

          it "logs a warning" do
            expect(logger).to receive(:warn).with("Exception parsing webhook metadata: '%'", ArgumentError)
            PactBrokerUrls.decode_pact_metadata(encoded_metadata)
          end
        end
      end

      describe "latest_verification_for_pact_url" do
        context "when permalink = true" do
          subject { PactBrokerUrls.latest_verification_for_pact_url(pact, base_url, true) }

          it { is_expected.to eq "http://example.org/pacts/provider/Bar%2FBar/consumer/Foo%2FFoo/pact-version/5hbfu/verification-results/latest" }
        end

        context "when permalink = false" do
          subject { PactBrokerUrls.latest_verification_for_pact_url(pact, base_url, false) }

          it { is_expected.to eq "http://example.org/pacts/provider/Bar%2FBar/consumer/Foo%2FFoo/version/123%2F456/verification-results/latest" }
        end
      end

      describe "matrix_for_pacticipant_version_url" do
        subject { PactBrokerUrls.matrix_for_pacticipant_version_url(version, base_url) }

        it { is_expected.to eq "http://example.org/matrix?q[][pacticipant]=Foo%2FFoo&q[][version]=2%2F4&latestby=cvpv" }
      end

      describe "matrix_badge_url" do
        subject { PactBrokerUrls.matrix_badge_url_for_selectors(consumer_selector, provider_selector, base_url) }
        let(:provider_selector) { PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: provider_name, tag: "meep", latest: true) }
        let(:consumer_selector) { PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: consumer_name, tag: "bar", latest: true) }

        it { is_expected.to eq "http://example.org/matrix/provider/Bar%2FBar/latest/meep/consumer/Foo%2FFoo/latest/bar/badge.svg" }
      end

      describe "tag_url" do
        subject { PactBrokerUrls.tag_url(base_url, tag) }

        it { is_expected.to match_route_in_api(PactBroker::API) }
        it { is_expected.to eq "http://example.org/pacticipants/Foo%2FFoo/versions/2%2F4/tags/feat%2Ffoo" }
      end
    end
  end
end
