require 'pact/shared/request'
require 'pact/shared/null_expectation'

module Pact
  module Request
    class Expected < Pact::Request::Base

      DEFAULT_OPTIONS = {:allow_unexpected_keys => false}.freeze
      attr_accessor :options, :generators

      def self.from_hash(hash)
        sym_hash = symbolize_keys hash
        method = sym_hash.fetch(:method)
        path = sym_hash.fetch(:path)
        query = sym_hash.fetch(:query, key_not_found)
        headers = sym_hash.fetch(:headers, key_not_found)
        body = sym_hash.fetch(:body, key_not_found)
        options = sym_hash.fetch(:options, {})
        generators = sym_hash.fetch(:generators, {})
        new(method, path, headers, body, query, options, generators)
      end

      def initialize(method, path, headers, body, query, options = {}, generators = {})
        super(method, path, headers, body, query)
        @generators = generators
        @options = options
      end

      def matches?(actual_request)
        difference(actual_request).empty?
      end

      def matches_route? actual_request
        require 'pact/matchers' # avoid recusive loop between pact/reification, pact/matchers and this file
        route = {:method => method.upcase, :path => path}
        other_route = {:method => actual_request.method.upcase, :path => actual_request.path}
        Pact::Matchers.diff(route, other_route).empty?
      end

      def difference(actual_request)
        require 'pact/matchers' # avoid recusive loop between pact/reification, pact/matchers and this file
        request_diff = Pact::Matchers.diff(to_hash_without_body_or_query, actual_request.to_hash_without_body_or_query)
        request_diff.merge!(query_diff(actual_request.query))
        request_diff.merge!(body_diff(actual_request.body))
      end

      protected

      def query_diff actual_query
        if specified?(:query)
          query_diff = query.difference(actual_query)
          query_diff.any? ? {query: query_diff} : {}
        else
          {}
        end
      end

      def self.key_not_found
        Pact::NullExpectation.new
      end

      private

      # Options is a dirty hack to allow Condor to send extra keys in the request,
      # as it's too much work to set up an exactly matching expectation.
      # Need to implement a proper matching strategy and remove this.
      # Do not rely on it!
      def runtime_options
        DEFAULT_OPTIONS.merge(symbolize_keys(options))
      end

      def body_diff(actual_body)
        if specified?(:body)
          body_difference = body_differ.call(body, actual_body, allow_unexpected_keys: runtime_options[:allow_unexpected_keys_in_body])
          return { body: body_difference } if body_difference.any?
        end
        {}
      end

      def body_differ
        Pact.configuration.body_differ_for_content_type content_type
      end
    end
  end
end
