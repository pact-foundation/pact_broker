module PactBroker
  module Api
    module Decorators
      module FormatDateTime
        # Keep this in sync with Sequel.datetime_class.
        # Needs to be upgraded from DateTime to Time as Time is deprecated
        DATE_TIME_CLASS = DateTime

        def self.call(date_time)
          if date_time.is_a?(String)
            DATE_TIME_CLASS.strptime(date_time).to_time.utc.to_datetime.xmlschema
          elsif date_time
            date_time.to_time.utc.to_datetime.xmlschema if date_time
          end
        end

        def format_date_time(date_time)
          FormatDateTime.call(date_time)
        end
      end
    end
  end
end
