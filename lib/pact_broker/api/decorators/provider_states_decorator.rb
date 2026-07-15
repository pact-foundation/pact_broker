
module PactBroker
  module Api
    module Decorators
      class ProviderStateDecorator < BaseDecorator
        camelize_property_names

        property :name, getter: -> (context) { context[:represented][:name] }
        property :params, getter: -> (context) { context[:represented][:params] }
        property :consumers, getter: -> (context) { context[:represented][:consumers] }
      end

      class ProviderStatesDecorator < BaseDecorator
        collection :providerStates, getter: -> (context) { 
          consumers_map = {}
            
            context[:represented].each do |item|
              item["providerStates"].each do |provider_state|
                provider_state = provider_state.to_h
                provider_state[:consumers] ||= []
                provider_state[:consumers] << item["consumer"]
                consumers_map[[provider_state[:name], provider_state[:params]]] ||= []
                consumers_map[[provider_state[:name], provider_state[:params]]] += provider_state[:consumers]
              end
            end

            consumers_map.map do |(name, params), consumers|
              { name: name, params: params, consumers: consumers.uniq }.transform_keys(&:to_sym)
            end
          .sort_by { |provider_state| provider_state[:name] }
        }, :extend => PactBroker::Api::Decorators::ProviderStateDecorator
      end
    end
  end
end
