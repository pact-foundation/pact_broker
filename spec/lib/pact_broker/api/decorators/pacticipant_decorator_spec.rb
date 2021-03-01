require 'spec_helper'
require 'pact_broker/api/decorators/pacticipant_decorator'
require 'pact_broker/domain/pacticipant'

module PactBroker
  module Api
    module Decorators
      describe PacticipantDecorator do
        describe "from_json" do
          let(:pacticipant) { OpenStruct.new }
          let(:decorator) { PacticipantDecorator.new(pacticipant) }
          let(:hash) do
            {
              name: "Foo",
              mainDevelopmentBranches: ["main"]
            }
          end

          subject { decorator.from_json(hash.to_json) }

          its(:name) { is_expected.to eq "Foo" }
          its(:main_development_branches) { is_expected.to eq ["main"] }
        end
        describe "to_json" do
          let(:pacticipant) do
            td.create_pacticipant('Name')
              .create_label('foo')
              .and_return(:pacticipant)
          end

          let(:created_at) { Time.new(2014, 3, 4) }
          let(:updated_at) { Time.new(2014, 3, 5) }
          let(:base_url) { 'http://example.org' }

          before do
            pacticipant.created_at = created_at
            pacticipant.updated_at = updated_at
            allow_any_instance_of(PacticipantDecorator).to receive(:templated_tag_url_for_pacticipant).and_return('version_tag_url')
          end

          subject { JSON.parse PacticipantDecorator.new(pacticipant).to_json(user_options: { base_url: base_url }), symbolize_names: true }

          it "includes timestamps" do
            expect(subject[:createdAt]).to eq FormatDateTime.call(created_at)
            expect(subject[:updatedAt]).to eq FormatDateTime.call(updated_at)
          end

          it "includes embedded labels" do
            expect(subject[:_embedded][:labels].first).to include name: 'foo'
            expect(subject[:_embedded][:labels].first[:_links][:self][:href]).to match %r{http://example.org/.*foo}
          end

          it "creates the URL for a version tag" do
            expect_any_instance_of(PacticipantDecorator).to receive(:templated_tag_url_for_pacticipant).with("Name", base_url)
            subject
          end

          it "includes a relation for a version tag" do
            expect(subject[:_links][:'pb:version-tag'][:href]).to eq "version_tag_url"
          end

          context "when there is a latest_version" do
            before { td.create_version("1.2.107") }
            it "includes an embedded latestVersion" do
              expect(subject[:_embedded][:latestVersion]).to include number: "1.2.107"
            end

            it "includes an embedded latest-version for backwards compatibility" do
              expect(subject[:_embedded][:'latest-version']).to include number: "1.2.107"
            end

            it "includes a deprecation warning" do
              expect(subject[:_embedded][:'latest-version']).to include title: "DEPRECATED - please use latestVersion"
            end
          end

          context "when there is no latest_version" do
            it "doesn't blow up" do
              expect(subject[:_embedded]).to_not have_key(:latestVersion)
              expect(subject[:_embedded]).to_not have_key(:'latest-version')
            end
          end
        end
      end
    end
  end
end
