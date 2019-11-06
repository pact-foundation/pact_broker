require 'pact_broker/ui/controllers/base_controller'
require 'pact_broker/ui/view_models/index_items'
require 'haml'

module PactBroker
  module UI
    module Controllers
      class Index < Base
        include PactBroker::Services

        get "/" do
          set_headers
          tags = nil
          if params[:tags]
            tags = params[:tags] == 'true' ? true : [*params[:tags]].compact
          end
          options = { tags: tags }
          options[:optimised] = true if params[:optimised] == 'true'
          view_model = ViewDomain::IndexItems.new(index_service.find_index_items(options))
          page = tags ? :'index/show-with-tags' : :'index/show'
          haml page, {locals: {index_items: view_model, title: "Pacts"}, layout: :'layouts/main'}
        end

        def set_headers
          response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
          response.headers["Pragma"] = "no-cache"
          response.headers["Expires"] = "0"
        end
      end
    end
  end
end
