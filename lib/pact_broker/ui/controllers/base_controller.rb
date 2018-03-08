require 'padrino-core'
require 'haml'
require 'pact_broker/services'

module PactBroker
  module UI
    module Controllers
      class Base < Padrino::Application

        set :root, File.join(File.dirname(__FILE__), '..')
        set :show_exceptions, ENV['RACK_ENV'] != 'production'

      end
    end
  end
end