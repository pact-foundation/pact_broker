module Rack
  module PactBroker
    # If the HTML and the CSV group resources are both requested by the browser,
    # Chrome gets confused by the content types, and when you click back, it tries to load the CSV
    # instead of the HTML page. So we have to give the CSV resource a different URL (.csv)

    class ConvertFileExtensionToAcceptHeader

      EXTENSION_REGEXP = /\.\w+$/.freeze
      EXTENSIONS = {
        ".csv" => "text/csv",
        ".svg" => "image/svg+xml",
        ".json" => "application/hal+json",
        ".yaml" => "application/yaml",
        ".css"  => "text/css",
        ".js" => "text/javascript"
      }

      def initialize app
        @app = app
      end

      def call env
        file_extension = extension(env)
        if convert_to_accept_header? file_extension
          @app.call(set_accept_header_and_path_info(env, file_extension))
        else
          @app.call(env)
        end
      end

      def convert_to_accept_header? file_extension
        EXTENSIONS[file_extension]
      end

      def extension env
        env["PATH_INFO"] =~ EXTENSION_REGEXP && $~[0]
      end

      def set_accept_header_and_path_info env, file_extension
        env.merge(
          "PATH_INFO" => env["PATH_INFO"].gsub(EXTENSION_REGEXP, ''),
          "HTTP_ACCEPT" => EXTENSIONS[file_extension]
        )
      end
    end
  end
end
