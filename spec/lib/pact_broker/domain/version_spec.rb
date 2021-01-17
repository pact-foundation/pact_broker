require 'pact_broker/domain/version'

module PactBroker
  module Domain
    describe Version do
      describe "for_selector" do
        subject { Version.for_selector(selector).all }

        def find_version(number)
          subject.find{ |v| v.number == number }
        end

        def version_numbers
          subject.collect(&:number).sort_by(&:to_i)
        end

        context "when selecting the latest prod versions without a pacticipant name" do
          before do
            td.create_consumer("Foo")
              .create_consumer_version("1", tag_names: %w{prod})
              .create_consumer_version("2", tag_names: %w{prod})
              .create_consumer("Bar")
              .create_consumer_version("10", tag_names: %w{prod})
              .create_consumer_version("11", tag_names: %w{prod})
          end

          let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: 'prod', latest: true) }

          it "returns the latest prod version for each pacticipant" do
            expect(version_numbers).to eq %w{2 11}
          end
        end

        context "when selecting the latest prod versions with a pacticipant name" do
          before do
            td.create_consumer("Foo")
              .create_consumer_version("1", tag_names: %w{prod})
              .create_consumer_version("2", tag_names: %w{prod})
              .create_consumer("Bar")
              .create_consumer_version("10", tag_names: %w{prod})
              .create_consumer_version("11", tag_names: %w{prod})
          end

          let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: 'Foo', tag: 'prod', latest: true) }


          it "returns the latest prod version for Foo" do
            expect(version_numbers).to eq %w{2}
          end
        end

        context "when selecting the latest version for branch main with a pacticipant name" do
          before do
            td.create_consumer("Foo")
              .create_consumer_version("1", branch: "main")
              .create_consumer_version("2", branch: "main")
              .create_consumer_version("3", branch: "not-main")
              .create_consumer("Bar")
              .create_consumer_version("10", branch: "main")
              .create_consumer_version("11", branch: "main")
          end

          let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: 'Foo', branch: 'main', latest: true) }


          it "returns the latest version for Foo with branch main" do
            expect(version_numbers).to eq %w{2}
          end
        end

        context "when selecting all prod versions without a pacticipant name" do
          before do
            td.create_consumer("Foo")
              .create_consumer_version("1", tag_names: %w{prod})
              .create_consumer_version("2", tag_names: %w{prod})
              .create_consumer("Bar")
              .create_consumer_version("10", tag_names: %w{prod})
              .create_consumer_version("11", tag_names: %w{prod master})
              .create_consumer_version("12", tag_names: %w{master})
          end

          let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: 'prod') }

          it "selects all the production versions without a pacticipant name" do
            expect(version_numbers).to eq %w{1 2 10 11}
          end
        end

        context "when selecting the latest version for each tag (head versions)" do
          before do
            td.create_consumer("Foo")
              .create_consumer_version("1", tag_names: %w{prod})
              .create_consumer_version("2", tag_names: %w{prod}).comment("yes")
              .create_consumer_version("3", tag_names: %w{master})
              .create_consumer_version("4", tag_names: %w{master}).comment("yes")
              .create_consumer("Bar")
              .create_consumer_version("10", tag_names: %w{prod})
              .create_consumer_version("11", tag_names: %w{prod}).comment("yes")
          end

          let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: true, latest: true) }

          it "selects the head versions for each tag" do
            expect(version_numbers).to eq %w{2 4 11}
          end

          context "when also specifying pacticipant name" do
            let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: true, latest: true, pacticipant_name: "Foo") }

            it "selects the head versions for each tag for the given pacticipant" do
              expect(version_numbers).to eq %w{2 4}
            end
          end
        end

        context "when selecting all tagged versions" do
          before do
            td.create_consumer("Foo")
              .create_consumer_version("1", tag_names: %w{prod})
              .create_consumer_version("2", tag_names: %w{prod})
              .create_consumer_version("4", tag_names: %w{master})
              .create_consumer_version("5")
              .create_consumer("Bar")
              .create_consumer_version("10", tag_names: %w{prod})
              .create_consumer_version("11")
          end

          let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: true) }

          it "selects every version with a tag" do
            expect(version_numbers).to eq %w{1 2 4 10}
          end

          context "when also specifying pacticipant name" do
            let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: true, pacticipant_name: "Foo") }

            it "selects every version with a tag for the given pacticipant" do
              expect(version_numbers).to eq %w{1 2 4}
            end
          end
        end

        context "when selecting all versions for a tag with max age" do
          before do
            td.set_now(four_days_ago)
              .create_consumer("Foo")
              .create_consumer_version("1", tag_names: %w{master})
              .add_days(1)
              .create_consumer_version("2", tag_names: %w{master})
              .create_consumer_version("3", tag_names: %w{master})
          end

          let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: 'master', max_age: max_age) }

          let(:max_age) { 3 }
          let(:four_days_ago) { Date.today - 4 }

          it "selects the consumer versions younger than the max age" do
            expect(version_numbers).to eq %w{2 3}
          end
        end
      end

      describe "#latest_pact_publication" do
        let!(:pact) do
          TestDataBuilder.new
            .create_consumer
            .create_provider
            .create_consumer_version
            .create_pact
            .revise_pact
            .and_return(:pact)
        end
        let(:version) { Version.order(:id).last }

        it "returns the latest pact revision for the consumer version" do
          expect(version.latest_pact_publication.id).to eq pact.id
        end
      end

      describe "uq_ver_ppt_ord" do
        let(:consumer) do
          TestDataBuilder.new
            .create_consumer
            .and_return(:consumer)
        end

        it "does not allow two versions with the same pacticipant and order" do
          Sequel::Model.db[:versions].insert(number: '1', order: 0, pacticipant_id: consumer.id, created_at: DateTime.new(2017), updated_at: DateTime.new(2017))
          expect { Sequel::Model.db[:versions].insert(number: '2', order: 0, pacticipant_id: consumer.id, created_at: DateTime.new(2017), updated_at: DateTime.new(2017)) }
            .to raise_error(Sequel::UniqueConstraintViolation)
        end
      end

      describe "tags_with_latest_flag" do
        before do
          td.create_consumer("foo")
            .create_consumer_version("1")
            .create_consumer_version_tag("dev")
            .create_consumer_version_tag("prod")
            .create_consumer_version("2")
            .create_consumer_version_tag("dev")
        end

        it "uneager loads" do
          version = Version.first(number: "1")
          expect(version.tags.collect(&:name).sort).to eq %w{dev prod}
          expect(version.tags_with_latest_flag.select(&:latest).collect(&:name)).to eq %w{prod}
        end

        it "eager loads" do
          version = Version.eager(:tags, :tags_with_latest_flag).where(number: "1").all.first
          expect(version.tags.collect(&:name).sort).to eq %w{dev prod}
          expect(version.tags_with_latest_flag.select(&:latest).collect(&:name)).to eq %w{prod}
        end
      end
    end
  end
end
