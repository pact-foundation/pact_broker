require 'pact/mock_service/request_handlers/interaction_post'
require 'pact/mock_service/request_handlers/interactions_put'
require 'pact/mock_service/request_handlers/index_get'
require 'pact/mock_service/request_handlers/interaction_delete'
require 'pact/mock_service/request_handlers/interaction_replay'
require 'pact/mock_service/request_handlers/log_get'
require 'pact/mock_service/request_handlers/options'
require 'pact/mock_service/request_handlers/missing_interactions_get'
require 'pact/mock_service/request_handlers/pact_post'
require 'pact/mock_service/request_handlers/session_delete'
require 'pact/mock_service/request_handlers/verification_get'
require 'pact/consumer/request'
require 'pact/support'

module Pact
  module MockService
    module RequestHandlers

      def self.new *args
        App.new(*args)
      end

      class App < ::Rack::Cascade
        def initialize name, logger, session, options
          super [
            Options.new(name, logger, options[:cors_enabled]),
            SessionDelete.new(name, logger, session),
            MissingInteractionsGet.new(name, logger, session),
            VerificationGet.new(name, logger, session),
            InteractionPost.new(name, logger, session, Pact::SpecificationVersion.new(options.fetch(:pact_specification_version))),
            InteractionsPut.new(name, logger, session, Pact::SpecificationVersion.new(options.fetch(:pact_specification_version))),
            InteractionDelete.new(name, logger, session),
            LogGet.new(name, logger),
            PactPost.new(name, logger, session),
            IndexGet.new(name, logger),
            InteractionReplay.new(name, logger, session, options[:cors_enabled], options[:stub_pactfile_paths])
          ]
        end
      end
    end
  end
end
