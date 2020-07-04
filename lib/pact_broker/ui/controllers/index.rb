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
          page_number = params[:page]&.to_i || 1
          # Make page size smaller for data intensive query
          page_size = params[:pageSize]&.to_i || (tags == true ? 30 : 100)
          options = {
            tags: tags,
            page_number: page_number,
            page_size: page_size
          }

          index_items = ViewDomain::IndexItems.new(index_service.find_index_items(options), base_url: base_url)

          page = tags ? :'index/show-with-tags' : :'index/show'
          locals = {
            title: "Pacts",
            index_items: index_items,
            page_number: page_number,
            page_size: page_size,
            pagination_record_count: index_items.pagination_record_count,
            current_page_size: index_items.size,
            base_url: base_url
          }

          haml page, {locals: locals, layout: :'layouts/main'}
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
