require 'grape'

require_relative 'api/index_api'
require_relative 'api/pacticipant_api'

module PactBroker
  class API < Grape::API
    content_type :json, 'application/json'
    content_type :xml, 'text/xml'
    default_format :json

    mount Api::IndexApi
    mount Api::PacticipantApi

  end
end
