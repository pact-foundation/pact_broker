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
          subject.collect(&:number)
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
            expect(version_numbers.sort).to eq %w{2 3}
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
    end
  end
end
