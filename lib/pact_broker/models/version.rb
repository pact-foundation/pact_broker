require 'sequel'

module PactBroker

  module Models

    class Version < Sequel::Model

      one_to_many :pacts
      one_to_one :pacticipant

      def to_s
        "Version: number=#{number}, pacticipant=#{pacticipant_id}"
      end
    end
  end
end