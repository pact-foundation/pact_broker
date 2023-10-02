require "pact_broker/api/decorators/pacticipant_decorator"
require "pact_broker/domain/pacticipant"

module PactBroker
  module Api
    module Decorators
      describe PacticipantDecorator do
        describe ".eager_load_associations" do
          subject { PacticipantDecorator }

          its(:eager_load_associations) { is_expected.to eq [:labels, :latest_version] }
        end

        describe "from_json" do
          let(:pacticipant) { OpenStruct.new }
          let(:decorator) { PacticipantDecorator.new(pacticipant) }
          let(:hash) do
            {
              name: "Foo",
              mainBranch: "main"
            }
          end

          subject { decorator.from_json(hash.to_json) }

          its(:name) { is_expected.to eq "Foo" }
          its(:main_branch) { is_expected.to eq "main" }
        end

        describe "to_json" do
          let(:pacticipant) do
            td.create_pacticipant("Name")
              .create_label("foo")
              .and_return(:pacticipant)
          end

          let(:created_at) { Time.new(2014, 3, 4) }
          let(:updated_at) { Time.new(2014, 3, 5) }
          let(:base_url) { "http://example.org" }

          before do
            pacticipant.created_at = created_at
            pacticipant.updated_at = updated_at
            allow_any_instance_of(PacticipantDecorator).to receive(:templated_tag_url_for_pacticipant).and_return("version_tag_url")
            allow_any_instance_of(PacticipantDecorator).to receive(:templated_version_url_for_pacticipant).and_return("version_url")
            allow_any_instance_of(PacticipantDecorator).to receive(:pacticipant_branches_url).and_return("pacticipant_branches_url")
          end

          subject { JSON.parse PacticipantDecorator.new(pacticipant).to_json(user_options: { base_url: base_url }), symbolize_names: true }

          it "includes timestamps" do
            expect(subject[:createdAt]).to eq FormatDateTime.call(created_at)
            expect(subject[:updatedAt]).to eq FormatDateTime.call(updated_at)
          end

          it "includes embedded labels" do
            expect(subject[:_embedded][:labels].first).to include name: "foo"
            expect(subject[:_embedded][:labels].first[:_links][:self][:href]).to match %r{http://example.org/.*foo}
          end

          it "includes a relation for a version tag" do
            expect_any_instance_of(PacticipantDecorator).to receive(:templated_tag_url_for_pacticipant).with("Name", base_url)
            expect(subject[:_links][:'pb:version-tag'][:href]).to eq "version_tag_url"
          end

          it "includes a relation for a version" do
            expect_any_instance_of(PacticipantDecorator).to receive(:templated_version_url_for_pacticipant).with("Name", base_url)
            expect(subject[:_links][:'pb:version'][:href]).to eq "version_url"
          end

          it "includes a relation for the branches" do
            expect_any_instance_of(PacticipantDecorator).to receive(:pacticipant_branches_url).with(pacticipant, base_url)
            expect(subject[:_links][:'pb:branches'][:href]).to eq "pacticipant_branches_url"
          end

          context "when there is a latest_version" do
            before { td.create_version("1.2.107") }

            it "has the options passed through correctly" do
              allow_any_instance_of(EmbeddedVersionDecorator).to receive(:version_url) do | _instance, actual_base_url, _actual_version |
                @actual_base_url = actual_base_url
                "version_url"
              end
              subject
              expect(@actual_base_url).to eq base_url
            end

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
