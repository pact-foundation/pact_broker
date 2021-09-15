require "pact_broker/config/runtime_configuration"

module PactBroker
  module Config
    describe RuntimeConfiguration do
      ATTRIBUTES = RuntimeConfiguration.config_attributes
      DOCUMENTATION = File.read("docs/configuration.yml")
      DOCUMENTED_ATTRIBUTES = YAML.load(DOCUMENTATION)["groups"].flat_map{ | group | group["vars"].keys.collect(&:to_sym) }
      DELIBERATELY_UNDOCUMENTED_ATTRIBUTES = [
        :warning_error_class_names,
        :log_configuration_on_startup,
        :use_hal_browser,
        :use_rack_protection,
        :use_case_sensitive_resource_names,
        :order_versions_by_date,
        :base_equality_only_on_content_that_affects_verification_results,
        :semver_formats,
        :seed_example_data,
        :use_first_tag_as_branch_time_limit,
        :validate_database_connection_config
      ]

      (ATTRIBUTES - DELIBERATELY_UNDOCUMENTED_ATTRIBUTES).each do | attribute_name |
        it "has documentation for #{attribute_name}" do
          expect(DOCUMENTED_ATTRIBUTES & [attribute_name]).to include(attribute_name)
        end
      end
    end
  end
end
