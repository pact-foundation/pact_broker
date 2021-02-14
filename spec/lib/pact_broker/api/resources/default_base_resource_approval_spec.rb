require 'pact_broker/api/resources'

module PactBroker
  module Api
    module Resources
      RSpec.describe "modifiable resources (ones that require write access)" do
        let(:pact_broker_resource_classes) do
          all_resources = ObjectSpace.each_object(::Class)
            .select { |klass| klass < DefaultBaseResource }
            .select(&:name)
            .reject { |klass| klass.name.end_with?("BaseResource") }
            .sort_by(&:name)
        end

        it "specifies which pacticipant is the one relevant to the policy" do
          data = pact_broker_resource_classes.collect do | resource_class |
            request = double('request', uri: URI("http://example.org")).as_null_object
            response = double('response')
            resource = resource_class.new(request, response)
            modifiable = resource.allowed_methods.any?{ | method | %w{PATCH POST PUT DELETE}.include?(method) }
            # We only care about getting the right pacticipant for the policy if the
            # resource itself can be modified.
            # Read only resources can be read by anybody - no point wasting time getting the right pacticipant
            if modifiable
              def resource.consumer
                'consumer'
              end

              def resource.provider
                'provider'
              end

              def resource.pacticipant
                'pacticipant'
              end

              def resource.resource_exists?
                true
              end

              resource_class_data = {
                resource_class_name: resource.class.name,
              }

              if resource.respond_to?(:policy_pacticipant)
                resource_class_data[:resource_class_data] = resource.policy_pacticipant
              end
              resource_class_data
            else
              nil
            end
          end.compact

          Approvals.verify({ resource_classes: data }, :name => 'modifiable_resources', format: :json)
        end
      end
    end
  end
end