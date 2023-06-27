
# Allows a default Rack middleware implementation to be set,
# and then be optionally changed out for a different implementation
# after the app has been built.
# Used for allowing the authorization code to set after the
# `app = PactBroker::App.new` has been called

module Rack
  module PactBroker
    class ConfigurableMakeItLater
      def initialize default_clazz
        @clazz = default_clazz
      end

      def make_it_later clazz
        @clazz = clazz
      end

      def new *args, &block
        @clazz.new(*args, &block)
      end
    end
  end
end
