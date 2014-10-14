require 'reform'
require 'reform/contract'

module PactBroker
  module Api
    module Contracts

      module RequestValidations
        def method_is_valid
          if http_method && !valid_method?
            errors.add(:method, "is not a recognised HTTP method")
          end
        end

        def valid_method?
          Net::HTTP.const_defined?(http_method.capitalize)
        end

        def url_is_valid
          if url && !url_valid?
            errors.add(:url, "is not a valid URL eg. http://example.org")
          end
        end

        def url_valid?
          uri && uri.scheme && uri.host
        end

        def uri
          begin
            URI(url)
          rescue URI::InvalidURIError
            nil
          end
        end
      end
    end
  end
end
