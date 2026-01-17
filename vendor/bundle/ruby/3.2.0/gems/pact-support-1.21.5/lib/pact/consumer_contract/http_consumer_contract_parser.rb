require 'pact/specification_version'

module Pact
  class HttpConsumerContractParser
    include SymbolizeKeys

    def call(hash)
      hash = symbolize_keys(hash)
      v = pact_specification_version(hash)
      options = { pact_specification_version: v }

      if v.after? 3
        Pact.configuration.error_stream.puts "WARN: This code only knows how to parse v3 pacts, attempting to parse v#{options[:pact_specification_version]} pact using v3 code."
      end

      interactions = hash[:interactions].each_with_index.collect { |hash, index| Interaction.from_hash({ index: index }.merge(hash), options) }
      ConsumerContract.new(
        :consumer => ServiceConsumer.from_hash(hash[:consumer]),
        :provider => ServiceProvider.from_hash(hash[:provider]),
        :interactions => interactions
      )
    end

    def pact_specification_version hash
      # TODO handle all 3 ways of defining this...
      # metadata.pactSpecificationVersion
      maybe_pact_specification_version_1 = hash[:metadata] && hash[:metadata]['pactSpecification'] && hash[:metadata]['pactSpecification']['version']
      maybe_pact_specification_version_2 = hash[:metadata] && hash[:metadata]['pactSpecificationVersion']
      pact_specification_version = maybe_pact_specification_version_1 || maybe_pact_specification_version_2
      pact_specification_version ? Pact::SpecificationVersion.new(pact_specification_version) : Pact::SpecificationVersion::NIL_VERSION
    end

    def can_parse?(hash)
      hash.key?('interactions') || hash.key?(:interactions)
    end
  end
end
