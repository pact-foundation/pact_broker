require 'pact_broker/ui/controllers/base_controller'
require 'pact_broker/ui/view_models/matrix_line'
require 'haml'

module PactBroker
  module UI
    module Controllers
      class Matrix < Base

        include PactBroker::Services

        get "/provider/:provider_name/consumer/:consumer_name" do
          selectors = [{ pacticipant_name: params[:consumer_name] }, { pacticipant_name: params[:provider_name] } ]
          lines = matrix_service.find(selectors)
          lines = lines.collect{|line| PactBroker::UI::ViewDomain::MatrixLine.new(line) }.sort
          locals = {
            lines: lines,
            title: "The Matrix",
            consumer_name: params[:consumer_name],
            provider_name: params[:provider_name]
          }
          haml :'matrix/show', {locals: locals, layout: :'layouts/main'}
        end

      end
    end
  end
end
