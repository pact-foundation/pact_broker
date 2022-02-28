module PactBroker
  module Api
    module Resources
      module BadgeMethods
        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def content_types_provided
          [["image/svg+xml", :to_svg]]
        end

        def resource_exists?
          false
        end

        # Only called if resource_exists? returns false
        def previously_existed?
          true
        end

        def forbidden?
          false
        end

        def is_authorized?(authorization_header)
          super || PactBroker.configuration.enable_public_badge_access
        end

        def policy_name
          :'badges::badge'
        end

        def moved_temporarily?
          response.headers["Cache-Control"] = "no-cache"
          begin
            badge_url
          rescue StandardError => e
            # Want to render a badge, even if there's an error
            badge_service.error_badge_url("error", ErrorResponseBodyGenerator.display_message(e, "reference: #{PactBroker::Errors.generate_error_reference}"))
          end
        end
      end
    end
  end
end
