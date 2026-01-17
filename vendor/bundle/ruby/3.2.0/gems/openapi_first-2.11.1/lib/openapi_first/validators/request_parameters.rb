# frozen_string_literal: true

module OpenapiFirst
  module Validators
    module RequestParameters
      RequestHeaders = Data.define(:schema) do
        def call(parsed_request)
          validation = schema.validate(parsed_request.headers)
          Failure.fail!(:invalid_header, errors: validation.errors) if validation.error?
        end
      end

      Path = Data.define(:schema) do
        def call(parsed_request)
          validation = schema.validate(parsed_request.path)
          Failure.fail!(:invalid_path, errors: validation.errors) if validation.error?
        end
      end

      Query = Data.define(:schema) do
        def call(parsed_request)
          validation = schema.validate(parsed_request.query)
          Failure.fail!(:invalid_query, errors: validation.errors) if validation.error?
        end
      end

      RequestCookies = Data.define(:schema) do
        def call(parsed_request)
          validation = schema.validate(parsed_request.cookies)
          Failure.fail!(:invalid_cookie, errors: validation.errors) if validation.error?
        end
      end

      VALIDATORS = {
        path_schema: Path,
        query_schema: Query,
        header_schema: RequestHeaders,
        cookie_schema: RequestCookies
      }.freeze

      def self.for(args)
        VALIDATORS.filter_map do |key, klass|
          schema = args[key]
          klass.new(schema) if schema
        end
      end
    end
  end
end
