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
          'webhook' => 'webhooks',
          'can-i-deploy-pacticipant-version-to-tag' => 'can-i-deploy',
          'pacticipant' => 'pacticipants'
        }.freeze

        helpers do
          def view_name_for rel_name, context = nil
            view_name = MAPPINGS[rel_name] || rel_name
            context ? "#{context}/#{view_name}" : view_name
          end

          def resource_exists? rel_name, context = nil
            File.exist? File.join(self.class.root, 'views', "#{view_name_for(rel_name, context)}.markdown")
          end
        end

        get ":rel_name" do
          rel_name = params[:rel_name]
          context = params[:context]
          view_params = {:layout_engine => :haml, layout: :'layouts/main'}
          if resource_exists? rel_name, context
            markdown view_name_for(rel_name, context).to_sym, view_params, {}
          elsif resource_exists? rel_name
            markdown view_name_for(rel_name).to_sym, view_params, {}
          else
            markdown :not_found, view_params, {}
          end
        end
      end
    end
  end
end