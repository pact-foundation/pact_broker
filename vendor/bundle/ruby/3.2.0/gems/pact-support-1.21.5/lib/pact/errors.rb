module Pact
  class Error < ::StandardError
  end

  # Raised when the interaction is not defined correctly
  class InvalidInteractionError < Error
    def initialize(interaction)
      super(build_message(interaction))
    end

    private

    def build_message(interaction)
      missing_attributes = []
      missing_attributes << :description unless interaction.description
      missing_attributes << :request unless interaction.request
      missing_attributes << :response unless interaction.response
      "Missing attributes: #{missing_attributes}"
    end
  end
end
