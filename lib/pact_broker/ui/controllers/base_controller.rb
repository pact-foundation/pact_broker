require 'padrino-core'
require 'haml'
require 'pact_broker/services'

module PactBroker
  module UI
    module Controllers
      class Base < Padrino::Application

        set :root, File.join(File.dirname(__FILE__), '..')
        set :show_exceptions, ENV['RACK_ENV'] != 'production'
        set :dump_errors, false # The padrino logger logs these for us. If this is enabled we get duplicate logging.

        def base_url
          PactBroker.configuration.base_url || request.base_url
        end
      end
    end
  end
end
