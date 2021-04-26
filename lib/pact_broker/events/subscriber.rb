require 'wisper'

module PactBroker
  module Events
    extend self

    def subscribe(*args)
      Wisper.subscribe(*args) do
        yield
      end
    end
  end
end
