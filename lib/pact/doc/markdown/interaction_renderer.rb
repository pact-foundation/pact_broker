require 'erb'
require 'pact/doc/interaction_view_model'
require 'rack/utils'

module Pact
  module Doc
    module Markdown
      class InteractionRenderer
        attr_reader :interaction

        def initialize interaction, pact
          @interaction = InteractionViewModel.new(interaction, pact)
        end

        def render_summary
          formatted_provider_states = h(interaction.formatted_provider_states)
          suffix = formatted_provider_states.empty? ? "" : " given #{formatted_provider_states}"
          "* [#{h(interaction.description(true))}](##{interaction.id})#{suffix}\n\n"
        end

        def render_full_interaction
          render('/interaction.erb')
        end

        def render template_file
          ERB.new(template_string(template_file)).result(binding)
        end

        # The template file is written with only ASCII range characters, so we
        # can read as UTF-8. But rendered strings must have same encoding as
        # script encoding because it will joined to strings which are produced by
        # string literal.
        def template_string(template_file)
          File.read(template_contents(template_file), external_encoding: Encoding::UTF_8).force_encoding(__ENCODING__)
        end

        def template_contents(template_file)
          File.dirname(__FILE__) + template_file
        end

        def h(text)
          Rack::Utils.escape_html(text)
        end
      end
    end
  end
end
