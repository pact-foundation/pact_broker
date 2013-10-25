require 'sinatra'

require_relative 'api/index_api'
require_relative 'api/pacticipant_api'
require_relative 'api/pact_api'

module PactBroker
  class API < Sinatra::Base
#    content_type :json, 'application/json'
#    content_type :xml, 'text/xml'
#    default_format :json

    use Api::IndexApi
    use Api::PacticipantApi
    use Api::PactApi

  end
end
