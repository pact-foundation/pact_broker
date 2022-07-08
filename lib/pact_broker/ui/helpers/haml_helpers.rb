require "haml"
require "pact_broker/string_refinements"

module Haml::Helpers
  using PactBroker::StringRefinements

  def blank?(thing)
    thing.blank?
  end
end
