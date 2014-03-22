require 'pact_broker/api/resources/base_resource'

module PactBroker::Api

  module Resources

    class Tag < BaseResource

      def content_types_provided
        [["application/hal+json", :to_json]]
      end

      def content_types_accepted
        [["application/json", :from_json]]
      end

      def allowed_methods
        ["GET","PUT"]
      end

      def from_json
        unless @tag
          @tag = tag_service.create identifier_from_path
          response.headers["Location"] = tag_url(resource_url, @tag)
        end
        response.body = generate_json @tag
      end

      def resource_exists?
        @tag = tag_service.find identifier_from_path
      end

      def to_json
        generate_json(@tag)
      end

      def generate_json tag
        PactBroker::Api::Decorators::TagDecorator.new(tag).to_json(base_url: resource_url)
      end

    end
  end

end
