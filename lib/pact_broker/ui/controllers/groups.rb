require 'pact_broker/ui/controllers/base_controller'
require 'pact_broker/ui/view_models/relationships'
require 'haml'

module PactBroker
  module UI
    module Controllers
      class Groups < Base

        include PactBroker::Services

        get ":name" do
          erb :'groups/show.html', {
            locals: {
              csv_path: "/groups/#{params[:name]}/csv",
              pacticipant_name: params[:name]}
            }, {
              layout: 'layouts/main'
            }
        end

      end
    end
  end
end