require 'pact_broker/ui/controllers/base_controller'
require 'pact_broker/ui/view_models/relationships'
require 'haml'

module PactBroker
  module UI
    module Controllers
      class Relationships < Base

        include PactBroker::Services

        get "/" do
          tags = [*params[:tags]].compact
          view_model = ViewDomain::Relationships.new(index_service.find_relationships(tags: tags))
          page = tags.any? ? :'relationships/show-prod-tags' : :'relationships/show'
          haml page, {locals: {relationships: view_model, title: "Pacts"}, layout: :'layouts/main'}
        end

      end
    end
  end
end
