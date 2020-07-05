require 'pact_broker/pacts/pact_publication_policy'
require 'pundit'

module PactBroker
  def self.current_user
    @current_user ||= OpenStruct.new
  end
end
