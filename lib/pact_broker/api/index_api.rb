require 'grape/api'
require 'pact_broker/logging'

module PactBroker
  module Api

    class IndexApi < Grape::API

      helpers do
        include PactBroker::Logging
      end

      # content_type :html, 'text/html'
      content_type :json, 'application/json' # Grape seems to be upset if we specify HTML without JSON

      default_format :json
      desc 'rea-rels:links'
      get '/' do

      end
    end
  end
end
