require 'pact_broker/webhooks/pact_and_verification_parameters'

module PactBroker
  module Webhooks
    class Render

      TEMPLATE_PARAMETER_REGEXP = /\$\{pactbroker\.[^\}]+\}/
      DEFAULT_ESCAPER = lambda { |it| it }

      def self.includes_parameter?(value)
        value =~ TEMPLATE_PARAMETER_REGEXP
      end

      def self.call(template, params, &escaper)
        render_template(escape_params(params, escaper || DEFAULT_ESCAPER), template)
      end

      def self.render_template(params, template)
        params.inject(template) do | template, (key, value) |
          template.gsub(key, value)
        end
      end

      def self.escape_params(params, escaper)
        params.keys.each_with_object({}) do | key, new_params |
          new_params[key] = escaper.call(params[key])
        end
      end
    end
  end
end
