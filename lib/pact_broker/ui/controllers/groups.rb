require "pact_broker/ui/controllers/base_controller"
require "pact_broker/ui/view_models/index_items"
require "haml"

# TODO handle 404 gracefully

module PactBroker
  module UI
    module Controllers
      class Groups < Base
        include PactBroker::Services

        get ":name" do
          erb :'groups/show.html', {
              locals: locals(tab: "details")
            }, {
              layout: "layouts/main",
            }
        end

        get ":name/network" do
          erb :'groups/show.html', {
              locals: locals(tab: "network")
            }, {
              layout: "layouts/main",
            }
        end

        def locals(overrides)
          pacticipant = pacticipant_service.find_pacticipant_by_name(params[:name])
          {
            csv_path: "#{base_url}/groups/#{ERB::Util.url_encode(params[:name])}.csv",
            max_pacticipants: PactBroker.configuration.network_diagram_max_pacticipants,
            pacticipant_name: params[:name],
            repository_url: pacticipant&.repository_url,
            base_url: base_url,
            pacticipant: pacticipant,
            details_url: "#{base_url}/pacticipants/#{ERB::Util.url_encode(params[:name])}",
            network_url: "#{base_url}/pacticipants/#{ERB::Util.url_encode(params[:name])}/network?maxPacticipants=#{PactBroker.configuration.network_diagram_max_pacticipants}"
          }.merge(overrides)
        end
      end
    end
  end
end