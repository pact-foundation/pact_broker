require "pact_broker/ui/controllers/base_controller"
require "pact_broker/ui/view_models/index_items"
require "haml"

module PactBroker
  module UI
    module Controllers
      class Dashboard < Base
        include PactBroker::Services

        get "/provider/:provider_name/consumer/:consumer_name" do
          set_headers
          consumer_name = params[:consumer_name]
          provider_name = params[:provider_name]
          view = params[:view] || index_service.smart_default_view(consumer_name, provider_name) || "branch"
          tags = view == "tag" || view == "all"
          page_number = params[:page]&.to_i || 1
          # Make page size smaller for data intensive query
          page_size = params[:pageSize]&.to_i || 30
          options = {
            tags: tags,
            page_number: page_number,
            page_size: page_size,
            consumer_name: params[:consumer_name],
            provider_name: params[:provider_name],
            view: view
          }.compact
          error_messages = []

          consumer = pacticipant_service.find_pacticipant_by_name(params[:consumer_name])
          provider = pacticipant_service.find_pacticipant_by_name(params[:provider_name])

          if !consumer
            error_messages << "No pacticipant found with name #{consumer_name}"
          end

          if !provider
            error_messages << "No pacticipant found with name #{provider_name}"
          end

          index_items = if consumer && provider
                          index_service.find_index_items(options)
                        else
                          []
                        end

          view_index_items = ViewDomain::IndexItems.new(index_items, base_url: base_url, view: view)

          page = :'dashboard/show'
          locals = {
            title: PactBroker::Messages.message("messages.dashboard.title", consumer_name: params[:consumer_name], provider_name: params[:provider_name]),
            index_items: view_index_items,
            page_number: page_number,
            page_size: page_size,
            pagination_record_count: view_index_items.pagination_record_count,
            current_page_size: view_index_items.size,
            base_url: base_url,
            errors: error_messages,
            tags: tags,
            view: view,
            consumer_name: params[:consumer_name],
            provider_name: params[:provider_name],
            consumer: consumer,
            provider: provider
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
