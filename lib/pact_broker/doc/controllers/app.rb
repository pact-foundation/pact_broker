require 'padrino-core'
require 'redcarpet'

Tilt.prefer Tilt::RedcarpetTemplate

module PactBroker
  module Doc
    module Controllers
      class App < Padrino::Application

        set :root, File.join(File.dirname(__FILE__), '..')
        set :show_exceptions, true

        MAPPINGS = {
          'webhooks-create' => 'webhooks',
          'webhooks-webhooks' => 'webhooks',
          'pact-webhooks' => 'webhooks',
        }.freeze

        helpers do
          def view_name_for rel_name
            MAPPINGS[rel_name] || rel_name
          end

          def resource_exists? rel_name
            File.exist? File.join(self.class.root, 'views', "#{view_name_for(rel_name)}.markdown")
          end
        end

        get ":rel_name" do
          rel_name = params[:rel_name]
          if resource_exists? rel_name
            markdown view_name_for(rel_name).to_sym, {:layout_engine => :haml, layout: :'layouts/main'}, {}
          else
            response.status = 404
          end
        end

      end
    end
  end
end