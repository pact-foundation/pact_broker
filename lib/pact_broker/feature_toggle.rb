module PactBroker
  class FeatureToggle
    def self.enabled?(feature)
      not_production? || feature_in_env_var?(feature)
    end

    def self.not_production?
      ENV['RACK_ENV'] != 'production'
    end

    def self.feature_in_env_var?(feature)
      (features =~ /\b#{feature}\b/i) != nil
    end

    def self.features
      ENV['PACT_BROKER_FEATURES'] || ""
    end
  end

  def self.feature_enabled?(feature)
    FeatureToggle.enabled?(feature)
  end
end
