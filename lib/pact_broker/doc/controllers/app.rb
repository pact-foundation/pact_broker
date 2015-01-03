require 'padrino-core'
require 'redcarpet'

Tilt.prefer Tilt::RedcarpetTemplate

module PactBroker
  module Doc
    module Controllers
      class App < Padrino::Application

        set :root, File.join(File.dirname(__FILE__), '..')
        set :show_exceptions, true

        helpers do
          def resource_exists? rel_name
            File.exist? File.join(self.class.root, 'views', "#{rel_name}.markdown")
          end
        end

        get ":rel_name" do
          rel_name = params[:rel_name]
          if resource_exists? rel_name
            markdown rel_name.to_sym, {:layout_engine => :haml, layout: :'layouts/main'}, {}
          else
            response.status = 404
          end
        end

      end
    end
  end
end