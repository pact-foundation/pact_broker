require 'padrino'
require 'haml'
require 'pact_broker/services'

module PactBroker
  module UI
    module Controllers
      class Base < Padrino::Application

        set :root, File.join(File.dirname(__FILE__), '..')

      end
    end
  end
end