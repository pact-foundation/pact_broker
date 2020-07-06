# This plugin can be included into a Sequel model to allow the original record
# to be loaded into the model if a duplicate is inserted.
# This is to handle race conditions when two requests come in in parallel to create
# the same resource.

# Rather than re-writing the whole save method and all the hooks and validation logic in it,
# it naughtily overrides the private _insert_dataset.

# MySQL does not return the id of the original row when a duplicate is inserted,
# so we have to manually find the original record an load it into the model.

module Sequel
  module Plugins
    module InsertIgnore
      def self.configure(model, opts=OPTS)
        model.instance_exec do
          @insert_ignore_identifying_columns = opts.fetch(:identifying_columns)
        end
      end

      module ClassMethods
        attr_reader :insert_ignore_identifying_columns
      end

      module InstanceMethods
        def insert_ignore(opts = {})
          save(opts)
        rescue Sequel::NoExistingObject
          # MySQL. Ruining it for everyone.
          query = self.class.insert_ignore_identifying_columns.each_with_object({}) do | column_name, q |
            q[column_name] = values[column_name]
          end
          self.id = model.where(query).single_record.id
          self.refresh
        end

        # Does the job for Sqlite and Postgres
        def _insert_dataset
          super.insert_ignore
        end
      end
    end
  end
end
