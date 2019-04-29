module PactBroker
  module Api
    module Decorators
      module FormatDateTime
        def self.call(date_time)
          date_time.to_time.utc.to_datetime.xmlschema if date_time
        end

        def format_date_time(date_time)
          FormatDateTime.call(date_time)
        end
      end
    end
  end
end
