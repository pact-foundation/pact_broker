require "pact_broker/ui/controllers/base_controller"
require "pact_broker/ui/view_models/index_items"
require "haml"

module PactBroker
  module UI
    module Controllers
      class Index < Base
        include PactBroker::Services

        get "/" do
          set_headers
          tags = if params[:tags]
                   params[:tags] == "true" ? true : [*params[:tags]].compact
                 end
          search = params[:search].present? ? params[:search] : nil
          page_number = params[:page]&.to_i || 1
          # Make page size smaller for data intensive query
          page_size = params[:pageSize]&.to_i || (tags == true ? 30 : 100)
          options = {
            tags: tags,
            page_number: page_number,
            page_size: page_size,
            search: search
          }.compact
          error_messages = []

          index_items = index_service.find_index_items(options)

          if index_items.blank? && !search.blank?
            error_messages << "No pacticipants found matching: \"#{search}\""
          end

          view_index_items = ViewDomain::IndexItems.new(index_items, base_url: base_url)

          page = tags ? :'index/show-with-tags' : :'index/show'
          locals = {
            title: PactBroker::Messages.message("messages.index.title"),
            index_items: view_index_items,
            page_number: page_number,
            page_size: page_size,
            pagination_record_count: view_index_items.pagination_record_count,
            current_page_size: view_index_items.size,
            base_url: base_url,
            errors: error_messages,
            tags: tags,
            search: search
          }

          haml page, { locals: locals, layout: :'layouts/main', escape_html: true }
        end

        private

        def set_headers
          response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
          response.headers["Pragma"] = "no-cache"
          response.headers["Expires"] = "0"
        end
      end
    end
  end
end
