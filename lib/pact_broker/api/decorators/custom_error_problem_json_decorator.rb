# Formats a message string into application/problem+json format.

module PactBroker
  module Api
    module Decorators
      class CustomErrorProblemJSONDecorator

        # @option title [String]
        # @option type [String]
        # @option detail [String]
        # @option status [Integer] HTTP status code
        def initialize(title:, type:, detail:, status: )
          @title = title
          @type = type
          @detail = detail
          @status = status
        end

        # @return [Hash]
        def to_hash(user_options: {}, **__other)
          {
            "title" => @title,
            "type" => "#{user_options[:base_url]}/problem/#{@type}",
            "detail" => @detail,
            "status" => @status
          }
        end

        # @return [String] JSON
        def to_json(*args, **kwargs)
          to_hash(*args, **kwargs).to_json
        end
      end
    end
  end
end
