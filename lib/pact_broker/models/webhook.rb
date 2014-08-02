module PactBroker

  module Models

    class Webhook
      attr_accessor :id, :consumer_id, :provider_id, :request
    end

    class WebhookRequest
      attr_accessor :method, :url, :headers, :body

      def execute
        #TODO make it work with https
        #TODO validation of method
        req = http_request

        headers.each do | header |
          req[header.name] = header.value
        end
        req.body = body
        response = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request req
        end

      end

      private

      def http_request
        Net::HTTP.const_get(method.capitalize).new(uri)
      end

      def uri
        URI(url)
      end
    end

    class WebhookRequestHeader
      attr_accessor :id, :name, :value
    end

  end

end
