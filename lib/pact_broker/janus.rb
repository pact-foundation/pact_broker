require "pact_broker/feature_toggle"

module PactBroker
  # Pact Janus contracts (https://github.com/rholshausen/pact-janus), published with
  # `specification: "janus"`. Everything here is behind the `janus` feature, which is off
  # unless PACT_BROKER_FEATURES names it, in every environment: with it off, nothing is
  # recognised as a Janus contract and the broker behaves exactly as it did before.
  #
  # A contract identifies itself by its `$format` member, so a stored contract is recognised
  # from its content, whatever specification it was published under. The broker does not
  # record the specification of a pact version.
  module Janus
    # The value of a publication's `specification` for a Janus contract.
    SPECIFICATION = "janus"

    # The `$format` of the Janus contracts the broker reads. A later major may change what an
    # interaction holds, so it is not recognised until the broker reads it.
    CONTRACT_FORMAT = "janus-contract/1"

    extend self

    def enabled?
      PactBroker.feature_enabled?(:janus, true)
    end

    # @param [Object] content a parsed document, with string or symbol keys
    # @return [Boolean] whether the feature is on and the document is a Janus contract
    def contract?(content)
      enabled? && format_of(content) == CONTRACT_FORMAT
    end

    # @return [Array<String>] the specifications a contract may be published under
    def specifications
      enabled? ? ["pact", SPECIFICATION] : ["pact"]
    end

    # A Janus interaction's identity: its description and its states (contract-file spec §4.2).
    def interaction_identity(interaction)
      [interaction["description"], interaction["states"] || []]
    end

    # A message is an emissive interaction (contract-file spec §4.3).
    def message?(interaction)
      interaction["transport"].is_a?(Hash) && interaction["transport"]["mode"] == "emissive"
    end

    private

    def format_of(content)
      return nil unless content.is_a?(Hash)
      content.fetch("$format") { content[:"$format"] }
    end
  end
end
