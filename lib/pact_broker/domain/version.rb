require 'pact_broker/db'
require 'pact_broker/domain/order_versions'
require 'pact_broker/repositories/helpers'
require 'pact_broker/environments/version_environment'

module PactBroker

  module Domain

    class Version < Sequel::Model

      set_primary_key :id
      one_to_many :pact_publications, order: :revision_number, class: "PactBroker::Pacts::PactPublication", key: :consumer_version_id
      associate(:many_to_one, :pacticipant, :class => "PactBroker::Domain::Pacticipant", :key => :pacticipant_id, :primary_key => :id)
      one_to_many :tags, :reciprocal => :version
      one_to_many :environments, :reciprocal => :version, :class => "PactBroker::Environments::VersionEnvironment"

      dataset_module do
        include PactBroker::Repositories::Helpers
      end

      def after_create
        OrderVersions.(self)
      end

      def to_s
        "Version: number=#{number}, pacticipant=#{pacticipant_id}"
      end

      def version_and_updated_date
        "Version #{number} - #{updated_at.to_time.localtime.strftime("%d/%m/%Y")}"
      end

      # What about provider??? This makes no sense
      def latest_pact_publication
        pact_publications.last
      end
    end

    Version.plugin :timestamps, :update_on_create=>true
  end
end