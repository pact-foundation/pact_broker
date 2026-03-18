require "padrino-core"
require "haml"

module PactBroker
  module Ui
    module Controllers
      class Clusters < Padrino::Application

        set :root, File.join(File.dirname(__FILE__), "..")

        class Cluster

          def initialize pacticipants, relationships

          end

        end

        get "/" do
          view_model = PactBroker::Ui::ViewModels::IndexItems.new(pacticipant_service.find_index_items, base_url: base_url)
          haml "clusters/show", locals: { relationships: view_model, base_url: base_url }, escape_html: true
        end

      end
    end
  end
end