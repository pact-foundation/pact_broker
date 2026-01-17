# frozen_string_literal: true

module Pact
  module V2
    module Matchers
      module V4
        class NotEmpty < Pact::V2::Matchers::Base
          def initialize(template = nil)
            @template = template
            super(spec_version: Pact::V2::Matchers::PACT_SPEC_V4, kind: 'notEmpty', template: @template)
          end

          def as_plugin
            if @template.nil? || @template.blank?
              raise MatcherInitializationError, "#{self.class}: template must be provided when calling as_plugin"
            end

            "notEmpty('#{@template}')"
          end
        end
      end
    end
  end
end
