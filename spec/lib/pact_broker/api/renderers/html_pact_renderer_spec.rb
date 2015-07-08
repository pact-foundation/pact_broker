require 'spec_helper'
require 'pact_broker/api/renderers/html_pact_renderer'

module PactBroker
  module Api
    module Renderers
      describe HtmlPactRenderer do

        before do
          ENV['BACKUP_TZ'] = ENV['TZ']
          ENV['TZ'] = "Australia/Melbourne"
        end

        after do
          ENV['TZ'] = ENV['BACKUP_TZ']
        end

        let(:consumer) { double('consumer', name: 'Consumer')}
        let(:provider) { double('provider', name: 'Provider')}
        let(:created_at) { DateTime.new(2014, 02, 27) }
        let(:json_content) { load_fixture('renderer_pact.json') }
        let(:pact) { double('pact', json_content: json_content, updated_at: created_at, consumer_version_number: '1.2.3', consumer: consumer, provider: provider)}
        let(:pact_url) { '/pact/url' }

        before do
          allow(PactBroker::Api::PactBrokerUrls).to receive(:pact_url).with('', pact).and_return(pact_url)
        end

        subject { HtmlPactRenderer.call pact }

        describe ".call" do
          it "renders the pact as HTML" do
            expect(subject).to include("<html>")
            expect(subject).to include("</html>")
            expect(subject).to include("<link rel='stylesheet'")
            expect(subject).to include("href='/stylesheets/github.css'")
            expect(subject).to include('<pre><code')
            expect(subject).to include('&quot;method&quot;:')
            expect(subject).to match /<h\d>.*Some Consumer/
            expect(subject).to match /<h\d>.*Some Provider/
            expect(subject).to include("Date published:")
            expect(subject).to include("Thu 27 Feb 2014, 11:00am +11:00")
          end

          context "when the content is not a valid pact, but is still JSON" do
            before do
              allow(pact).to receive(:content_hash).and_return(content_hash)
            end
            let(:json_content) { '[1]' }
            let(:content_hash) { [1] }

            it "includes a dismissive title" do
              expect(subject).to include "A contract between Consumer and Provider"
            end

            it "includes a warning" do
              expect(subject).to include "Note:"
            end

            it "renders the JSON in HTML" do
              expect(subject).to match /\[\s+1\s+\]/m
            end

            it "logs a warning" do
              allow(PactBroker.logger).to receive(:warn).with(/Error/)
              expect(PactBroker.logger).to receive(:warn).with(/Could not parse/)
              subject
            end
          end
        end

      end
    end
  end
end