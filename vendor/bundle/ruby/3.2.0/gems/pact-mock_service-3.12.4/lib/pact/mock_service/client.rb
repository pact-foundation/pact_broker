require 'net/http'
require 'pact/mock_service/interaction_decorator'
require 'pact/errors'

module Pact
  module MockService

    class VerificationFailedError < Pact::Error; end
    class AddInteractionError < Pact::Error; end
    class WritePactError < Pact::Error; end

    class Client

      MOCK_SERVICE_ADMINISTRATON_HEADERS = {'X-Pact-Mock-Service' => 'true'}

      def initialize port, host = 'localhost'
        @http = Net::HTTP.new(host, port)
      end

      def verify example_description
        response = http.request_get("/interactions/verification?example_description=#{CGI.escape(example_description)}", MOCK_SERVICE_ADMINISTRATON_HEADERS)
        raise VerificationFailedError.new("\e[31m#{response.body}\e[m") unless response.is_a? Net::HTTPSuccess
      end

      def log msg
        http.request_get("/log?msg=#{CGI.escape(msg)}", MOCK_SERVICE_ADMINISTRATON_HEADERS)
      end

      def wait_for_interactions wait_max_seconds, poll_interval
        wait_until_true(wait_max_seconds, poll_interval) do
          response = http.request_get("/interactions/missing", MOCK_SERVICE_ADMINISTRATON_HEADERS)
          JSON.parse(response.body)['size'] == 0
        end
      end

      def clear_interactions example_description
        http.delete("/interactions?example_description=#{CGI.escape(example_description)}", MOCK_SERVICE_ADMINISTRATON_HEADERS)
      end

      def add_expected_interaction interaction
        response = http.request_post(
          '/interactions',
          interaction_json(interaction),
          MOCK_SERVICE_ADMINISTRATON_HEADERS.merge("Content-Type" => "application/json")
        )
        raise AddInteractionError.new("\e[31m#{response.body}\e[m") unless response.is_a? Net::HTTPSuccess
      end

      def self.clear_interactions mock_service_base_url, example_description
        uri = URI(mock_service_base_url)
        Net::HTTP.new(uri.host, uri.port).delete("/interactions?example_description=#{CGI.escape(example_description)}", MOCK_SERVICE_ADMINISTRATON_HEADERS)
      end

      def write_pact pacticipant_details
        response = http.request_post("/pact", pacticipant_details.to_json, MOCK_SERVICE_ADMINISTRATON_HEADERS.merge("Content-Type" => "application/json"))
        raise WritePactError.new("\e[31m#{response.body}\e[m") unless response.is_a? Net::HTTPSuccess
        response.body
      end

      private

      attr_reader :http

      #todo: in need a better home (where can we move it?)
      def wait_until_true timeout=3, interval=0.1
        time_limit = Time.now + timeout
        loop do
          result =  yield
          return if result || Time.now >= time_limit
          sleep interval
        end
      end

      def interaction_json interaction
        Pact::MockService::InteractionDecorator.new(interaction).to_json
      end
    end
  end
end
