# frozen_string_literal: true

# This is a modified version of the Rack::Cascade class from https://github.com/rack/rack/blob/2833813/lib/rack/cascade.rb
# that short circuts the cascade if a response body is provided for a 404/403 response.
# This is to allow the UI and API to be in a cascade, but allows the UI
# to return a 404 page when the route matches, but there is no domain object found.
# If we don't do this, then the 404 from the UI causes an API response to be returned.


# This does not work. Do not use it. Have not yet worked out why.

module Rack
  # Rack::Cascade tries a request on several apps, and returns the
  # first response that is not 404 or 405 (or in a list of configured
  # status codes).  If all applications tried return one of the configured
  # status codes, return the last response.

  module PactBroker
    class Cascade
      # deprecated, no longer used
      NotFound = [404, { CONTENT_TYPE => "text/plain" }, []]

      # An array of applications to try in order.
      attr_reader :apps

      # Set the apps to send requests to, and what statuses result in
      # cascading.  Arguments:
      #
      # apps: An enumerable of rack applications.
      # cascade_for: The statuses to use cascading for.  If a response is received
      #              from an app, the next app is tried.
      def initialize(apps, cascade_for = [404, 405])
        @apps = []
        apps.each { |app| add app }

        @cascade_for = {}
        [*cascade_for].each { |status| @cascade_for[status] = true }
      end

      # Call each app in order.  If the responses uses a status that requires
      # cascading, try the next app.  If all responses require cascading,
      # return the response from the last app.
      def call(env)
        return [404, { CONTENT_TYPE => "text/plain" }, []] if @apps.empty?
        result = nil
        last_body = nil

        @apps.each_with_index do |app, i|
          # The SPEC says that the body must be closed after it has been iterated
          # by the server, or if it is replaced by a middleware action. Cascade
          # replaces the body each time a cascade happens. It is assumed that nil
          # does not respond to close, otherwise the previous application body
          # will be closed. The final application body will not be closed, as it
          # will be passed to the server as a result.
          last_body.close if last_body.respond_to? :close
          result = app.call(env)

          puts result.last

          # If it is a 404/403 AND the response body is empty, then try the next app
          if @cascade_for.include?(result[0].to_i) && result[2].respond_to?(:empty?) && result[2].empty?
            last_body = result[2]
          else
            puts "returned from #{i} of #{@apps.size}"
            # otherwise, return the result
            return result
          end
        end

        result
      end

      # Append an app to the list of apps to cascade.  This app will
      # be tried last.
      def add(app)
        @apps << app
      end

      # Whether the given app is one of the apps to cascade to.
      def include?(app)
        @apps.include?(app)
      end

      alias_method :<<, :add
    end
  end
end
