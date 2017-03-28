require 'reform'
require 'reform/form/dry'

require 'pact_broker/version'
require 'pact_broker/logging'
require 'pact_broker/app'

module PactBroker
  Reform::Form.class_eval do
    feature Reform::Form::Dry
  end
end
