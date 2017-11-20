require 'spec_helper'
require 'pact_broker/api/renderers/html_pact_renderer'
require 'timecop'

module PactBroker
  module Api
    module Renderers
      describe HtmlPactRenderer do

        before do
          ENV['BACKUP_TZ'] = ENV['TZ']
          ENV['TZ'] = "Australia/Melbourne"
          PactBroker.configuration.enable_public_badge_access = true

          Timecop.freeze(created_at + 3)
        end

        after do
          ENV['TZ'] = ENV['BACKUP_TZ']
          Timecop.return
        end

        let(:consumer) { double('consumer', name: 'Consumer')}
        let(:provider) { double('provider', name: 'Provider')}
        let(:created_at) { DateTime.new(2014, 02, 27) }
        let(:json_content) { load_fixture('renderer_pact.json') }
        let(:pact) { double('pact', json_content: json_content, consumer_version_number: '1.2.3', consumer: consumer, provider: provider, consumer_version_tag_names: ['prod', 'master'], created_at: created_at)}
        let(:pact_url) { '/pact/url' }
        let(:options) do
          {
            base_url: 'http://base',
            badge_url: 'http://badge'
           }
        end

        before do
          allow(PactBroker::Api::PactBrokerUrls).to receive(:pact_url).with('', pact).and_return(pact_url)
        end

        subject { HtmlPactRenderer.call pact, options }

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
            expect(subject).to include("3 days ago")
            expect(subject).to match /title.*Pact between Consumer and Provider/
            expect(subject).to match /prod, master/
          end

          it "renders the badge image" do
            expect(subject).to include "<img src='http://badge'/>"
          end

          it "renders a text area with the badge markdown" do
            expect(subject).to include "<textarea"
            expect(subject).to include "[![Consumer/Provider Pact Status](http://badge)](http://base)"
          end

          context "when enable_public_badge_access is false" do
            before do
              PactBroker.configuration.enable_public_badge_access = false
            end

            it "renders a message instructing the user to turn public access on" do
              expect(subject).to include "set `enable_public_badge_access` to true in the configuration"
            end
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