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
          # Using the X-Forwarded headers in the UI can leave the app vulnerable
          # https://www.acunetix.com/blog/articles/automated-detection-of-host-header-attacks/
          # Either use the explicitly configured base url or an empty string,
          # rather than request.base_url, which uses the X-Forwarded headers.
          env["pactbroker.base_url"] || ''
        end
      end
    end
  end
end
