require 'pact_broker/db'

module PactBroker

  module Models
    class Pact < Sequel::Model

      set_primary_key :id
      associate(:many_to_one, :provider, :class => "PactBroker::Models::Pacticipant", :key => :provider_id, :primary_key => :id)
      associate(:many_to_one, :consumer_version, :class => "PactBroker::Models::Version", :key => :version_id, :primary_key => :id)

      #Need to work out how to do this properly!
      def consumer_version_number
        values[:consumer_version_number]
      end

      def consumer
        consumer_version.pacticipant
      end

      def to_s
        "Pact: provider_id=#{provider_id} created_at=#{created_at} updated_at=#{updated_at}"
      end

      def to_json options = {}
        json_content
      end

      def name
        "Pact between #{consumer.name} (v#{consumer_version_number}) and #{provider.name}"
      end

      def version_and_updated_date
        "Version #{consumer_version_number} - #{updated_at.to_time.localtime.strftime("%d/%m/%Y")}"
      end
    end

    Pact.plugin :timestamps, :update_on_create=>true
  end
end
