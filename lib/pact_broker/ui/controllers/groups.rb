require 'pact_broker/ui/controllers/base_controller'
require 'pact_broker/ui/view_models/relationships'
require 'haml'

module PactBroker
  module UI
    module Controllers
      class Groups < Base

        include PactBroker::Services

        set :root, File.join(File.dirname(__FILE__), '..')

        get ":name" do
          erb :'group/show.html', {locals: {csv_path: "/groups/#{params[:name]}"}}, {layout: 'layouts/main'}
        end

      end
    end
  end
end