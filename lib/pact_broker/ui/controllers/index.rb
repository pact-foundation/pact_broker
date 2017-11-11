require 'pact_broker/ui/controllers/base_controller'
require 'pact_broker/ui/view_models/index_items'
require 'haml'

module PactBroker
  module UI
    module Controllers
      class Index < Base

        include PactBroker::Services

        get "/" do
          tags = [*params[:tags]].compact
          view_model = ViewDomain::IndexItems.new(index_service.find_index_items(tags: tags))
          page = tags.any? ? :'index/show-with-tags' : :'index/show'
          haml page, {locals: {index_items: view_model, title: "Pacts"}, layout: :'layouts/main'}
        end

      end
    end
  end
end
