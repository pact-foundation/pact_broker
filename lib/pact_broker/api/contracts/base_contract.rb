require "reform"
require "reform/form/dry"

Reform::Form.class_eval do
  feature Reform::Form::Dry
end

module PactBroker
  module Api
    module Contracts
      class BaseContract < Reform::Form
      end
    end
  end
end
