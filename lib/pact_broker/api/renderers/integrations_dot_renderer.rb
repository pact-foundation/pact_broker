module PactBroker
  module Api
    module Renderers
      class IntegrationsDotRenderer
        def initialize(integrations)
          @integrations = integrations
        end

        def self.call(integrations)
          new(integrations).call
        end

        def call
          "digraph { ranksep=3; ratio=auto; overlap=false; node [  shape = plaintext, fontname = Helvetica ];
#{integrations_graph}
}
"
        end

        private

        attr_reader :integrations

        def integrations_graph
          integrations
            .collect{ | integration| "  #{escape_name(integration.consumer_name)} -> #{escape_name(integration.provider_name)}" }
            .join("\n")
        end

        def escape_name(name)
          name.gsub(" ", "_")
        end
      end
    end
  end
end
