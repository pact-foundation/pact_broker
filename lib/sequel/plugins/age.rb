require "moments"

module Sequel
  module Plugins
    module Age
      module InstanceMethods
        def age
          @age ||= Moments.difference(Time.now, created_at.to_time)
        end
      end
    end
  end
end
