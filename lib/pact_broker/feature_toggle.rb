module PactBroker
  class FeatureToggle

    def self.enabled?(feature)
      ENV['RACK_ENV'] != 'production' || (ENV['PACT_BROKER_FEATURES'] || "").include?(feature.to_s)
    end

  end

  def self.feature_enabled?(feature)
    FeatureToggle.enabled?(feature)
  end
end
