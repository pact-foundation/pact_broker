require 'wisper'

# The Wisper implementation of temporary listeners clears all listeners at the end of the block,
# rather the just the ones that were supplied in block. This implementation just clears the specified ones,
# allowing multiple temporary overlapping listeners.

module PactBroker
  module Events
    class TemporaryListeners < Wisper::TemporaryListeners
      def subscribe(*listeners, &block)
        options = listeners.last.is_a?(Hash) ? listeners.pop : {}
        begin
          listeners.each { |listener| registrations << Wisper::ObjectRegistration.new(listener, options) }
          yield
        ensure
          unsubscribe(listeners)
        end
        self
      end

      def unsubscribe(listeners)
        registrations.delete_if do |registration|
          listeners.include?(registration.listener)
        end
      end
    end
  end
end


module PactBroker
  module Events
    extend self

    def subscribe(*args)
      result = nil
      TemporaryListeners.subscribe(*args) do
        result = yield
      end
      result
    end
  end
end
