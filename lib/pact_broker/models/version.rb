require 'sequel'

module PactBroker

  module Models

    class Version < Sequel::Model

      one_to_many :pacts
      associate(:many_to_one, :pacticipant, :class => "PactBroker::Models::Pacticipant", :key => :pacticipant_id, :primary_key => :id)

      def to_s
        "Version: number=#{number}, pacticipant=#{pacticipant_id}"
      end
    end
  end
end