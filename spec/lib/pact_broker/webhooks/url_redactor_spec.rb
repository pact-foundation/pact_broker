require 'pact_broker/webhooks/url_redactor'

module PactBroker
  module Webhooks
    describe URLRedactor do
      describe ".call" do

        context 'when there is no sensitive data in the url' do
          let(:url) do
            "http://example.org/hook"
          end
          it 'is shown as is' do
            expect(URLRedactor.call(url)).to eq "http://example.org/hook"
          end
        end

        context 'when there is no sensitive params in the url' do
          let(:url) do
            "http://example.org/hook?param=wenwant"
          end
          it 'is shown as is' do
            expect(URLRedactor.call(url)).to eq "http://example.org/hook?param=wenwant"
          end
        end

        context 'when the url contains a slack token' do
          let(:url) do
            "https://hooks.slack.com/services/aaa/bbb/ccc"
          end
          it 'redacts the token' do
            expect(URLRedactor.call(url)).to eq "https://hooks.slack.com/services/aaa/bbb/redacted"
          end
        end

        context 'when the url contains a token param' do
          let(:url) do
            "https://secure.server.com/?token=thatneedstobehidden"
          end
          it 'redacts the token' do
            expect(URLRedactor.call(url)).to eq "https://secure.server.com/?token=redacted"
          end
        end

        context 'when the url contains an auth param' do
          let(:url) do
            "https://secure.server.com/?auth=thatneedstobehidden"
          end
          it 'redacts the auth param' do
            expect(URLRedactor.call(url)).to eq "https://secure.server.com/?auth=redacted"
          end
        end

        context 'when the url contains a param name containing the word token' do
          let(:url) do
            "https://secure.server.com/?circle-token=thatneedstobehidden"
          end
          it 'redacts the token' do
            expect(URLRedactor.call(url)).to eq "https://secure.server.com/?circle-token=redacted"
          end
        end

        context 'when the url contains multiple params including a token param at the start of the url' do
          let(:url) do
            "https://secure.server.com/?token=thatwedont&param=thatwewant"
          end
          it 'redacts the token' do
            expect(URLRedactor.call(url)).to eq "https://secure.server.com/?token=redacted&param=thatwewant"
          end
        end

        context 'when the url contains multiple params including a token param at the end of the url' do
          let(:url) do
            "https://secure.server.com/?param=thatwewant&token=thatwedont"
          end
          it 'redacts the token' do
            expect(URLRedactor.call(url)).to eq "https://secure.server.com/?param=thatwewant&token=redacted"
          end
        end

        context 'when the url contains multiple params including an auth param at the start of the url' do
          let(:url) do
            "https://secure.server.com/?auth=thatwedont&param=thatwewant"
          end
          it 'redacts the auth param' do
            expect(URLRedactor.call(url)).to eq "https://secure.server.com/?auth=redacted&param=thatwewant"
          end
        end

        context 'when the url contains multiple params including an auth param at the end of the url' do
          let(:url) do
            "https://secure.server.com/?param=thatwewant&auth=thatwedont"
          end
          it 'redacts the auth param' do
            expect(URLRedactor.call(url)).to eq "https://secure.server.com/?param=thatwewant&auth=redacted"
          end
        end

      end
    end
  end
end
