require 'webmachine'

module PactBroker
  module Diagnostic
    module Resources
      class BaseResource < Webmachine::Resource
        def initialize
          PactBroker.configuration.before_resource.call(self)
        end

        def finish_request
          PactBroker.configuration.after_resource.call(self)
        end
      end
    end
  end
end
