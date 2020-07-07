# This plugin can be included into a Sequel model to allow the original record
# to be loaded into the model if a duplicate is inserted.
# This is to handle race conditions when two requests come in in parallel to create
# the same resource.

# Rather than re-writing the whole save method and all the hooks and validation logic in it,
# it naughtily overrides the private _insert_dataset.

module Sequel
  module Plugins
    module InsertIgnore
      def self.configure(model, opts=OPTS)
        model.instance_exec do
          @insert_ignore_plugin_identifying_columns = opts.fetch(:identifying_columns)
        end
      end

      module ClassMethods
        attr_reader :insert_ignore_plugin_identifying_columns
      end

      module InstanceMethods
        def insert_ignore(opts = {})
          save(opts)
          load_values_from_previously_inserted_object unless id
          self
        rescue Sequel::NoExistingObject
          load_values_from_previously_inserted_object
        end

        def load_values_from_previously_inserted_object
          query = self.class.insert_ignore_plugin_identifying_columns.each_with_object({}) do | column_name, q |
            q[column_name] = values[column_name]
          end
          self.id = model.where(query).single_record.id
          refresh
        end

        # naughty override of Sequel private method
        def _insert_dataset
          super.insert_ignore
        end
      end
    end
  end
end
