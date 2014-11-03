require 'pact_broker/ui/controllers/base_controller'
require 'pact_broker/ui/view_models/relationships'
require 'haml'

module PactBroker
  module UI
    module Controllers
      class Relationships < Base

        include PactBroker::Services

        get "/" do
          view_model = ViewDomain::Relationships.new(pacticipant_service.find_relationships)

          haml :'relationships/show', {locals: {relationships: view_model}}, {layout: 'layouts/main'}
        end

      end
    end
  end
end