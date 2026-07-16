require "pact_broker/matrix/unresolved_selector"

module MatrixBaseline
  # The representative request catalogue for the matrix seed. Each shape
  # crosses an axis that changes the query plan: selector cardinality,
  # selector type, latestby, limit, and the matrix-vs-can-i-deploy path.
  class Shapes
    Shape = Struct.new(:id, :label, :kind, :selectors, :options)

    # rubocop:disable Metrics/MethodLength
    def self.call(seed)
      anchors = seed.fetch(:anchors)
      providers = seed.fetch(:providers)
      both = seed.fetch(:both)
      environment = seed.fetch(:environment)

      consumer = anchors.fetch(:consumer)
      consumer_version = anchors.fetch(:consumer_version)
      provider = anchors.fetch(:provider)
      provider_version = anchors.fetch(:provider_version)
      downstream = anchors.fetch(:downstream)
      middle_tier = anchors.fetch(:both)

      sel = ->(**attrs) { PactBroker::Matrix::UnresolvedSelector.new(**attrs) }

      [
        Shape.new(
          "single_selector_version", "1 selector, version-specified", :matrix,
          [sel.(pacticipant_name: consumer, pacticipant_version_number: consumer_version)],
          { latestby: "cvpv", limit: "100" }
        ),
        Shape.new(
          "single_selector_name_only", "1 selector, name-only", :matrix,
          [sel.(pacticipant_name: consumer)],
          { latestby: "cvpv", limit: "100" }
        ),
        Shape.new(
          "two_selectors_version", "2 selectors, version-specified", :matrix,
          [sel.(pacticipant_name: consumer, pacticipant_version_number: consumer_version),
           sel.(pacticipant_name: provider, pacticipant_version_number: provider_version)],
          { latestby: "cvpv", limit: "100" }
        ),
        Shape.new(
          "five_selectors", "5 selectors", :matrix,
          [sel.(pacticipant_name: consumer)] + downstream.map { |d| sel.(pacticipant_name: d) },
          { latestby: "cvpv", limit: "100" }
        ),
        Shape.new(
          "large_n_selectors", "large-N selectors", :matrix,
          [sel.(pacticipant_name: consumer)] + (providers + both).map { |p| sel.(pacticipant_name: p) },
          { latestby: "cvpv", limit: "100" }
        ),
        Shape.new(
          "can_i_deploy_latest", "can-i-deploy, 1 selector + latest, no limit", :can_i_deploy,
          [sel.(pacticipant_name: consumer, pacticipant_version_number: consumer_version)],
          { latestby: "cvp", latest: true }
        ),
        Shape.new(
          "can_i_deploy_environment", "can-i-deploy --to-environment", :can_i_deploy,
          [sel.(pacticipant_name: consumer, pacticipant_version_number: consumer_version)],
          { latestby: "cvpv", environment_name: environment }
        ),
        Shape.new(
          "no_latestby_every_row", "no-latestby (EveryRow)", :matrix,
          [sel.(pacticipant_name: consumer, pacticipant_version_number: consumer_version)],
          { limit: "100" }
        ),
        Shape.new(
          "success_filter", "with success filter", :matrix,
          [sel.(pacticipant_name: consumer, pacticipant_version_number: consumer_version)],
          { latestby: "cvpv", success: [true], limit: "100" }
        ),
        Shape.new(
          "middle_tier_matrix", "single selector on a service that is both consumer and provider", :matrix,
          [sel.(pacticipant_name: middle_tier)],
          { latestby: "cvpv", limit: "100" }
        ),
      ]
    end
    # rubocop:enable Metrics/MethodLength
  end
end
