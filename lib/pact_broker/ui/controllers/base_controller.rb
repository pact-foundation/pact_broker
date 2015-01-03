require 'padrino-core'
require 'haml'
require 'pact_broker/services'

module PactBroker
  module UI
    module Controllers
      class Base < Padrino::Application

        set :root, File.join(File.dirname(__FILE__), '..')
        set :show_exceptions, true

      end
    end
  end
end