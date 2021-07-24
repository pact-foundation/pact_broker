require "pact_broker/config/runtime_configuration"

module PactBroker
  class FeatureToggle
    def self.enabled?(feature, ignore_env)
      if ignore_env
        feature_in_env_var?(feature)
      else
        not_production? || feature_in_env_var?(feature)
      end
    end

    def self.not_production?
      ENV["RACK_ENV"] != "production"
    end

    def self.feature_in_env_var?(feature)
      PactBroker.configuration.features.include?(feature.to_s.downcase)
    end
  end

  def self.feature_enabled?(feature, ignore_env = false)
    FeatureToggle.enabled?(feature, ignore_env)
  end
end
