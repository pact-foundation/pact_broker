require 'spec_helper'
require 'pact/doc/markdown/consumer_contract_renderer'
require 'pact/support'

module Pact
  module Doc
    module Markdown
      describe ConsumerContractRenderer do
        let(:consumer_contract) { Pact::ConsumerContract.from_uri './spec/support/markdown_pact.json' }
        let(:expected_output) { File.read("./spec/support/generated_markdown.md", external_encoding: Encoding::UTF_8) }

        subject { ConsumerContractRenderer.new(consumer_contract) }

        describe "#call" do
          context "when using V3 specification" do
            context "when an interaction has multiple provider states" do
              let(:consumer_contract) { Pact::ConsumerContract.from_uri './spec/support/markdown_pact_v3.json' }

              it "displays all provider states in the interaction title" do
                expect(subject.call).to include 'Given **alligators exist** and **the city of Tel Aviv has a zoo** ' \
                                                'and **the zoo keeps record of its alligator population**, upon receiving'
              end
            end
          end

          context "with markdown characters in the pacticipant names" do
            let(:consumer_contract) { Pact::ConsumerContract.from_uri './spec/support/markdown_pact_with_markdown_chars_in_names.json' }

            it "escapes the markdown characters" do
              expect(subject.call).to include '### A pact between Some\*Consumer\*App and Some\_Provider\_App'
              expect(subject.call).to include '#### Requests from Some\*Consumer\*App to Some\_Provider\_App'
            end
          end

          context "with ruby's default external encoding is not UTF-8" do
            around do |example|
              back = nil
              WarningSilencer.enable { back, Encoding.default_external = Encoding.default_external, Encoding::ASCII_8BIT }
              example.run
              WarningSilencer.enable { Encoding.default_external = back }
            end

            it "renders the interactions" do
              expect(subject.call).to eq(expected_output)
            end
          end

          it "renders the interactions" do
            expect(subject.call).to eq(expected_output)
          end

          context "when the pact fields have html embedded in them" do
            let(:consumer_contract) { Pact::ConsumerContract.from_uri './spec/support/markdown_pact_with_html.json' }

            its(:title) { is_expected.to include "&lt;h1&gt;Consumer&lt;&#x2F;h1&gt;" }
            its(:title) { is_expected.to include "&lt;h1&gt;Provider&lt;&#x2F;h1&gt;" }

            its(:summaries_title) { is_expected.to include "&lt;h1&gt;Consumer&lt;&#x2F;h1&gt;" }
            its(:summaries_title) { is_expected.to include "&lt;h1&gt;Provider&lt;&#x2F;h1&gt;" }

            its(:summaries) { is_expected.to include "&lt;h1&gt;alligators&lt;/h1&gt;" }
            its(:summaries) { is_expected.to_not include "<h1>alligators</h1>" }

            its(:full_interactions) { is_expected.to include "&lt;h1&gt;alligators&lt;/h1&gt;" }
            its(:full_interactions) { is_expected.to_not include "<h1>alligators</h1>" }
          end
        end
      end
    end
  end
end
