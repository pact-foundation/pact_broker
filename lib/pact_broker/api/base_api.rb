require 'pact_broker/logging'
require 'pact_broker/repositories'
require 'sequel'
require 'sinatra'
require 'sinatra/json'
require 'sinatra/namespace'
require 'sinatra/param'
require 'pact_broker/models'
require 'pact_broker/services'

module PactBroker

  module Api

    class BaseApi < Sinatra::Base

      helpers do
        include PactBroker::Logging
        include PactBroker::Services
      end

      set :raise_errors, false
      set :show_exceptions, false


      error do
        e = env['sinatra.error']
        logger.error e
        content_type :json
        status 500
        {:message => e.message, :backtrace => e.backtrace }.to_json
      end

      helpers Sinatra::JSON
      helpers Sinatra::Param
      register Sinatra::Namespace

    end
  end
end
