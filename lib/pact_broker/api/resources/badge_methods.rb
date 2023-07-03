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
            error_reference = log_and_report_error(e)
            badge_service.error_badge_url("error", "reference: #{error_reference}")
          end
        end

        def badge_url
          raise NotImplementedError
        end

        private

        def label
          lab = request.query["label"]
          lab && !lab.empty? ? lab : nil
        end
      end
    end
  end
end
