require 'reform'
require 'reform/form/dry'

require 'pact_broker/version'
require 'pact_broker/logging'
require 'pact_broker/app'
require 'pact_broker/db/log_quietener'

module PactBroker
  Reform::Form.class_eval do
    feature Reform::Form::Dry
  end
end
