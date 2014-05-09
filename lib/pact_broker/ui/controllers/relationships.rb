require 'pact_broker/ui/controllers/base_controller'
require 'pact_broker/ui/view_models/relationships'

module PactBroker
  module UI
    module Controllers
      class Relationships < Base

        include PactBroker::Services

        set :root, File.join(File.dirname(__FILE__), '..')

        get "/" do
          view_model = ViewModels::Relationships.new(pacticipant_service.find_relationships)
          render 'relationships/show', locals: {relationships: view_model}, layout: 'layouts/main'
        end

      end
    end
  end
end